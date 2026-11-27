/// The remote off-switch. `switches.json` on the data site (`site/` in the
/// repo) names the phone's sources to leave alone, by their status names
/// (`ceypetco`, `cbsl`, `cbsl-market`, `harti`, `edlcare`, `psc`), so every
/// phone stops calling one within about an hour, with no app update, if it
/// misbehaves or its site asks.
library;

import 'dart:convert';

const switchesPath = 'switches.json';

/// The sources [body] pauses: none when there is no file or it can't be read.
Set<String> pausedSources(String? body) {
  if (body == null) {
    return const {};
  }
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return const {};
  }
  return switch (json) {
    {'paused': final List<Object?> paused} => {...paused.whereType<String>()},
    _ => const {},
  };
}
