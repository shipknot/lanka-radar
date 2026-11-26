part of 'alerts_cubit.dart';

final class AlertsState extends Equatable {
  const AlertsState({
    this.loaded = false,
    this.on = const {},
    this.quiet = const QuietHours(),
    this.lastSync,
    this.notificationsAllowed = true,
    this.exactAlarmsAllowed = true,
    this.hasPlaces = false,
  });

  /// False until the settings are first read.
  final bool loaded;

  /// The switches that are on.
  final Set<AlertSwitch> on;
  final QuietHours quiet;

  /// When the background sync last ran; null if it never has.
  final DateTime? lastSync;

  /// Whether Android lets the app post notifications.
  final bool notificationsAllowed;

  /// Whether Android lets the load shedding reminders come on time.
  final bool exactAlarmsAllowed;

  /// Whether a place is watched, so there are load shedding reminders to set.
  final bool hasPlaces;

  /// Load shedding reminders are set, but Android may hold them up to an hour.
  bool get remindersMayBeLate =>
      !exactAlarmsAllowed && hasPlaces && on.contains(AlertSwitch.power);

  AlertsState copyWith({Set<AlertSwitch>? on, QuietHours? quiet}) =>
      AlertsState(
        loaded: loaded,
        on: on ?? this.on,
        quiet: quiet ?? this.quiet,
        lastSync: lastSync,
        notificationsAllowed: notificationsAllowed,
        exactAlarmsAllowed: exactAlarmsAllowed,
        hasPlaces: hasPlaces,
      );

  @override
  List<Object?> get props => [
    loaded,
    on,
    quiet,
    lastSync,
    notificationsAllowed,
    exactAlarmsAllowed,
    hasPlaces,
  ];
}
