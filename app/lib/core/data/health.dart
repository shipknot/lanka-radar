import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:lanka_radar/core/data/now_data.dart';

/// Names for the workflow's sources (status.json) in the order they are shown.
const githubSources = {
  'gazettes': 'Gazettes',
  'weekly': 'Weekly gazette',
  'exams': 'Exam notices',
  'gas': 'LP gas (Litro)',
  'laugfs': 'LP gas (Laugfs)',
  'holidays': 'Holidays',
  'rates': 'USD/LKR backup',
};

/// How one source last went.
final class SourceHealth extends Equatable {
  const SourceHealth({
    required this.name,
    this.lastRun,
    this.lastSuccess,
    this.lastError,
    this.onPhone = false,
    this.paused = false,
  });

  final String name;
  final DateTime? lastRun;
  final DateTime? lastSuccess;

  /// Null when the last run worked.
  final String? lastError;

  /// Read by the phone itself. Those sources only answer inside Sri Lanka, so
  /// one that has never answered may just be out of reach (a phone abroad).
  final bool onPhone;

  /// Left alone on purpose, by the data site's `switches.json`.
  final bool paused;

  /// Never answered on this phone, which only a phone source is let off for.
  bool get notReached =>
      onPhone && !paused && lastRun != null && lastSuccess == null;

  /// Tried, but no success for a day or more; a phone source only once it has
  /// answered here. A paused source is never stale.
  bool isStale(DateTime now) =>
      !paused &&
      lastRun != null &&
      (lastSuccess == null
          ? !onPhone
          : now.difference(lastSuccess!) > staleAfter);

  @override
  List<Object?> get props => [
    name,
    lastRun,
    lastSuccess,
    lastError,
    onPhone,
    paused,
  ];
}

/// The health of every source: what GitHub's workflow reads (and when it last
/// ran) and what the phone reads itself.
final class Health extends Equatable {
  const Health({
    this.workflowRan,
    this.github = const [],
    this.phone = const [],
  });

  /// When the workflow last ran, from status.json.
  final DateTime? workflowRan;
  final List<SourceHealth> github;
  final List<SourceHealth> phone;

  bool workflowStale(DateTime now) =>
      workflowRan != null && now.difference(workflowRan!) > staleAfter;

  /// Something has gone quiet: the app bar shows a warning.
  bool needsALook(DateTime now) =>
      workflowStale(now) ||
      [...github, ...phone].any((source) => source.isStale(now));

  @override
  List<Object?> get props => [workflowRan, github, phone];
}

/// The workflow's status.json as health rows, in [githubSources] order.
({DateTime? ran, List<SourceHealth> sources}) parseWorkflowStatus(
  String? body,
) {
  if (body == null) {
    return (ran: null, sources: const []);
  }
  final json = jsonDecode(body) as Map<String, Object?>;
  final sources = (json['sources'] as Map<String, Object?>?) ?? const {};
  return (
    ran: _time(json['checked']),
    sources: [
      for (final MapEntry(key: id, value: name) in githubSources.entries)
        if (sources[id] case final Map<String, Object?> entry)
          SourceHealth(
            name: name,
            lastRun: _time(entry['lastRun']),
            lastSuccess: _time(entry['lastSuccess']),
            lastError: entry['lastError'] as String?,
          ),
    ],
  );
}

DateTime? _time(Object? value) =>
    value is String ? DateTime.parse(value).toLocal() : null;
