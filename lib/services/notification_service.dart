import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      final localName = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      await requestPermissions();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImplementation?.requestNotificationsPermission();
        return granted ?? true;
      } else if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  NotificationDetails _getNotificationDetails({
    String? soundName,
    String channelId = 'taskflow_channel',
    String channelName = 'Task Reminders',
    String channelDescription = 'Notifications for scheduled tasks and deadlines',
  }) {
    AndroidNotificationSound? androidSound;
    if (soundName != null && soundName != 'default') {
      androidSound = RawResourceAndroidNotificationSound(soundName);
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      sound: androidSound,
      playSound: true,
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> scheduleTaskNotification(Task task, {String sound = 'default', int minutesBefore = 0}) async {
    if (task.id == null || task.isCompleted) return;

    try {
      final scheduledDate = task.dueDate.subtract(Duration(minutes: minutesBefore));
      if (scheduledDate.isBefore(DateTime.now())) {
        return; // Don't schedule in past
      }

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      final details = _getNotificationDetails(soundName: sound);

      String bodyText = task.description?.isNotEmpty == true
          ? task.description!
          : 'Task is due ${minutesBefore == 0 ? "now" : "in $minutesBefore minutes"}!';

      if (task.subtasks.isNotEmpty) {
        bodyText += ' (${task.completedSubtaskCount}/${task.subtasks.length} subtasks done)';
      }

      await _notificationsPlugin.zonedSchedule(
        id: task.id!,
        title: 'Task Reminder: ${task.title}',
        body: bodyText,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id.toString(),
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelTaskNotification(int taskId) async {
    try {
      await _notificationsPlugin.cancel(id: taskId);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String sound = 'default',
  }) async {
    try {
      final details = _getNotificationDetails(soundName: sound);
      await _notificationsPlugin.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }
}
