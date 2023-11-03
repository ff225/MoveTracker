import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static final NotificationHelper _instance = NotificationHelper._internal();

  factory NotificationHelper() {
    return _instance;
  }

  @pragma('vm:entry-point')
  NotificationHelper._internal() {
    _configureLocalTimeZone();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/launch_background');
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );
  }

  Future<void> showNotification(
    int id,
    String title,
    String body,
    NotificationDetails notificationDetails,
  ) async {
    await flutterLocalNotificationsPlugin.show(
        id, title, body, notificationDetails);
  }

  /// Set right date and time for notifications
  tz.TZDateTime _convertTime(int hour, int minutes) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minutes,
    );
    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }
    return scheduleDate;
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
  }

  /// Scheduled Notification
  Future<void> scheduledNotification(
    int id,
    String title,
    String body,
    NotificationDetails notificationDetails, {
    required int hour,
    required int minutes,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _convertTime(hour, minutes),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  cancelAll() async => flutterLocalNotificationsPlugin.cancelAll();
}
