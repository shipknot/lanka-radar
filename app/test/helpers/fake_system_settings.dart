import 'package:lanka_radar/core/system_settings.dart';

/// Records which of the app's settings pages would have opened.
class FakeSystemSettings implements SystemSettings {
  final opened = <String>[];

  @override
  Future<void> openApp() async => opened.add('app');

  @override
  Future<void> openNotifications() async => opened.add('notifications');

  @override
  Future<void> openAlarms() async => opened.add('alarms');
}
