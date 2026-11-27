import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_radar/core/data/switches.dart';

void main() {
  test('names the sources the file pauses', () {
    expect(pausedSources('{"paused": ["edlcare", "psc"]}'), {'edlcare', 'psc'});
    expect(pausedSources('{"paused": []}'), isEmpty);
  });

  test('a missing or unreadable file pauses nothing', () {
    expect(pausedSources(null), isEmpty);
    expect(pausedSources('<html>Not found</html>'), isEmpty);
    expect(pausedSources('{"paused": "edlcare"}'), isEmpty);
    expect(pausedSources('["edlcare"]'), isEmpty);
    expect(pausedSources('{"paused": ["cbsl", 3, null]}'), {'cbsl'});
  });
}
