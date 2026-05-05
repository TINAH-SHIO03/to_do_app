import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:actitvities/models/task.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_stat_notify');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) {
            navigatorKey.currentState?.pushNamed(
              '/notification',
              arguments: payload,
            );
          }
          debugPrint('Notification tapped: $payload');
        },
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      debugPrint('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing NotificationService: $e\n$stackTrace');
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 0,
    String payload = '',
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'theme_channel',
          'Theme Notifications',
          channelDescription: 'Notifications for theme changes',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_notify',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> scheduleTaskNotification({
    required Task task,
    required int notificationId,
    String? customPayload,
  }) async {
    try {
      final dateParts = task.date.split('-');
      final timeParts = task.startTime.split(':');

      final scheduledDateTime = tz.TZDateTime(
        tz.local,
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      if (scheduledDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('Scheduled time is in the past: $scheduledDateTime');
        return;
      }

      final payload = 'task|${task.title}|Task starts at ${task.startTime}';

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        task.title,
        task.note.isNotEmpty ? task.note : 'Task starts soon',
        scheduledDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Notifications for task start time',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_stat_notify',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task|${task.title}|${task.note}',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
        'Scheduled task notification: ID=$notificationId, Title=${task.title}, Time=scheduledDateTime, Payload=$payload',
      );
    } catch (e, stackTrace) {
      debugPrint('Error scheduling task notification: $e\n$stackTrace');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('Notification cancelled: ID=$id');
    } catch (e, stackTrace) {
      debugPrint('Error cancelling notification: $e\n$stackTrace');
    }
  }
}
