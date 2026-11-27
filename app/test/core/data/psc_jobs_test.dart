import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_radar/core/data/feed_item.dart';
import 'package:lanka_radar/core/data/psc_jobs.dart';

import '../../helpers/fake_sources.dart';

const _uploads = 'https://psc.gov.lk/images/latest_document/psc_announcements';

PscAnnouncement _titled(String title, {int stamp = 1789464305}) =>
    PscAnnouncement(stamp: stamp, title: title, pdf: '$_uploads/x.pdf');

int _seconds(DateTime utc) => utc.millisecondsSinceEpoch ~/ 1000;

void main() {
  test('reads each announcement once with its full title, newest first', () {
    final found = parsePscAnnouncements(fixture('psc_home.html'));

    expect(
      [for (final one in found) one.stamp],
      [
        1792139366,
        1791862394,
        1789723381,
        1789464305,
        1789450911,
        1693975072,
        1689930609,
      ],
    );
    final legal = found.firstWhere((one) => one.stamp == 1789464305);
    expect(
      legal.title,
      'Recruitment to the Posts of Legal Officer (Executive Service Grade '
      'III) in Environment Ministry - Open Stream - 2026',
    );
    expect(
      legal.pdf,
      '$_uploads/2026/1789464305-Recruitment-to-the-Posts-of-Legal-Officer'
      '--English.pdf',
    );
    expect(legal.day, '2026-09-15');
    expect(
      found.firstWhere((one) => one.stamp == 1789450911).title,
      contains('Primary Grade Officers & Agriculture Monitoring Officers'),
    );
  });

  test('uses the link text when the link has no title', () {
    const page =
        '<a href="/images/latest_document/psc_announcements/2026/'
        '1789464305-x.pdf">Recruitment of\n <b>Officers</b></a>';

    expect(parsePscAnnouncements(page).single.title, 'Recruitment of Officers');
  });

  test('a page without announcements is an error', () {
    expect(
      () => parsePscAnnouncements('<html><body>Maintenance</body></html>'),
      throwsFormatException,
    );
  });

  test('only recruitments and calls for applications are jobs', () {
    expect(_titled('Recruitment to the Posts of Legal Officer').isJob, isTrue);
    expect(
      _titled('Open Recruitment of Sri Lanka Education Administrative').isJob,
      isTrue,
    );
    expect(
      _titled('Calling for Applications for the post of Director').isJob,
      isTrue,
    );
    expect(
      _titled('Annual Transfer Appeals Decisions (Medical Officers)').isJob,
      isFalse,
    );
    expect(
      _titled('Formulation of Annual Internal Transfer Procedures').isJob,
      isFalse,
    );
  });

  test('the day is the one in Sri Lanka', () {
    final morning = _titled(
      'Recruitment',
      stamp: _seconds(DateTime.utc(2025, 12, 31, 18, 40)),
    );
    final evening = _titled(
      'Recruitment',
      stamp: _seconds(DateTime.utc(2025, 12, 31, 18, 20)),
    );

    expect(morning.day, '2026-01-01');
    expect(evening.day, '2025-12-31');
    expect(pscJobItems([morning, evening]), hasLength(1));
  });

  test("makes the workflow's item for each recruitment since 2026", () {
    final items = pscJobItems(parsePscAnnouncements(fixture('psc_home.html')));

    expect(
      [for (final item in items) item['id']],
      ['jobs-psc-1789723381', 'jobs-psc-1789464305'],
    );
    expect(items[1], {
      'id': 'jobs-psc-1789464305',
      'source': 'jobs',
      'topic': 'jobs',
      'issuer': 'Public Service Commission',
      'headline': {
        'en':
            'Recruitment to the Posts of Legal Officer (Executive Service '
            'Grade III) in Environment Ministry - Open Stream - 2026',
        'ta': null,
      },
      'keyNumbers': const <Object?>[],
      'published': '2026-09-15',
      'effective': null,
      'links': {
        'pdf_en':
            '$_uploads/2026/1789464305-Recruitment-to-the-Posts-of-Legal-'
            'Officer--English.pdf',
        'page': 'https://psc.gov.lk/index.php?lang=en',
      },
      'data': const <String, Object?>{},
      'alert': true,
    });
    expect(FeedItem.fromJson(items[1]).topic, 'jobs');
  });

  test('an announcement is kept and read back as it was', () {
    final legal = parsePscAnnouncements(fixture('psc_home.html'))[3];

    expect(PscAnnouncement.fromJson(legal.toJson()), legal);
  });
}
