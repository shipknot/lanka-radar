/// The Public Service Commission's recruitments. The workflow read them until
/// psc.gov.lk stopped answering servers abroad (November 2026); the phone
/// reads them now by the workflow's rules: the same page, the same posts and
/// the same item IDs, so the workflow's earlier items and the phone's never
/// double up.
library;

import 'package:equatable/equatable.dart';
import 'package:lanka_radar/core/format/dates.dart';

/// The Commission's homepage, which lists its latest announcements.
final pscPage = Uri.parse('https://psc.gov.lk/index.php?lang=en');

/// Where the announcements the phone last read are kept.
const pscAnnouncementsPath = 'phone/psc-announcements.json';

/// Recruitments put up before this day are left out, as the workflow did.
const pscHistoryStart = '2026-01-01';

const _site = 'https://psc.gov.lk';
const _sriLanka = Duration(hours: 5, minutes: 30);

final _link = RegExp(
  r'<a\b([^>]*\bhref="(/images/latest_document/psc_announcements/\d{4}/'
  r'(\d{9,11})-[^"]+\.pdf)"[^>]*)>(.*?)</a>',
  caseSensitive: false,
  dotAll: true,
);
final _title = RegExp(r'\btitle="([^"]*)"', caseSensitive: false);
final _tags = RegExp('<[^>]+>');
final _spaces = RegExp(r'\s+');
final _entity = RegExp(r'&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);');
final _job = RegExp(
  r'recruit|vacanc|calling for applications|'
  r'applications (?:are )?(?:invited|called)',
  caseSensitive: false,
);

/// An announcement on the homepage: a PDF named with the time it was put up,
/// in Unix seconds.
final class PscAnnouncement extends Equatable {
  const PscAnnouncement({
    required this.stamp,
    required this.title,
    required this.pdf,
  });

  factory PscAnnouncement.fromJson(Map<String, Object?> json) =>
      PscAnnouncement(
        stamp: json['stamp']! as int,
        title: json['title']! as String,
        pdf: json['pdf']! as String,
      );

  final int stamp;
  final String title;
  final String pdf;

  /// The day it was put up in Sri Lanka, yyyy-MM-dd.
  String get day => isoDay(
    DateTime.fromMillisecondsSinceEpoch(
      stamp * 1000,
      isUtc: true,
    ).add(_sriLanka),
  );

  /// A recruitment or a call for applications; transfers and appeal decisions
  /// are not jobs.
  bool get isJob => _job.hasMatch(title);

  Map<String, Object?> toJson() => {'stamp': stamp, 'title': title, 'pdf': pdf};

  @override
  List<Object?> get props => [stamp, title, pdf];
}

/// Every announcement on the homepage, newest first, once each. The link's
/// title has the post's full name; the text inside it is sometimes cut short.
List<PscAnnouncement> parsePscAnnouncements(String page) {
  final found = <int, PscAnnouncement>{};
  for (final link in _link.allMatches(page)) {
    final stamp = int.parse(link[3]!);
    final title = _unescape(
      _title.firstMatch(link[1]!)?[1] ?? link[4]!.replaceAll(_tags, ' '),
    ).replaceAll(_spaces, ' ').trim();
    if (title.isNotEmpty && !found.containsKey(stamp)) {
      found[stamp] = PscAnnouncement(
        stamp: stamp,
        title: title,
        pdf: '$_site${link[2]}',
      );
    }
  }
  if (found.isEmpty) {
    throw const FormatException(
      "No announcements on the Public Service Commission's homepage",
    );
  }
  return found.values.toList()..sort((a, b) => b.stamp.compareTo(a.stamp));
}

/// The workflow's items for the recruitments among [announcements].
List<Map<String, Object?>> pscJobItems(List<PscAnnouncement> announcements) => [
  for (final announcement in announcements)
    if (announcement.isJob && announcement.day.compareTo(pscHistoryStart) >= 0)
      {
        'id': 'jobs-psc-${announcement.stamp}',
        'source': 'jobs',
        'topic': 'jobs',
        'issuer': 'Public Service Commission',
        'headline': {'en': announcement.title, 'ta': null},
        'keyNumbers': const <Object?>[],
        'published': announcement.day,
        'effective': null,
        'links': {'pdf_en': announcement.pdf, 'page': '$pscPage'},
        'data': const <String, Object?>{},
        'alert': true,
      },
];

/// The few character references the homepage uses in its titles.
String _unescape(String text) => text.replaceAllMapped(_entity, (match) {
  final name = match[1]!;
  final code = switch (name[0]) {
    '#' when name[1] == 'x' || name[1] == 'X' => int.tryParse(
      name.substring(2),
      radix: 16,
    ),
    '#' => int.tryParse(name.substring(1)),
    _ => switch (name) {
      'amp' => 0x26,
      'lt' => 0x3C,
      'gt' => 0x3E,
      'quot' => 0x22,
      'apos' => 0x27,
      'nbsp' => 0x20,
      _ => null,
    },
  };
  return code == null ? match[0]! : String.fromCharCode(code);
});
