import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import 'web_notification/web_notification_manager.dart';

typedef InAppNotificationCallback = void Function(String title, String body);

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Active timers for Flutter Web scheduling
  static final Map<int, Timer> _webTimers = {};

  // Global callback for in-app heads-up alert banner
  static InAppNotificationCallback? onInAppNotification;

  // Notification channel ID for Android heads-up popup banner
  static const String channelId = 'taskflow_popup_channel_v4';
  static const String channelName = 'TaskFlow Urgent Alerts';
  static const String channelDescription = 'Popup heads-up alerts with sound and banner like WhatsApp';

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      await WebNotificationManager.instance.initialize();
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();

      // Accurately match device's timezone offset
      final offset = DateTime.now().timeZoneOffset;
      String? matchedName;
      for (final name in tz.timeZoneDatabase.locations.keys) {
        final loc = tz.getLocation(name);
        if (loc.currentTimeZone.offset == offset) {
          matchedName = name;
          break;
        }
      }
      if (matchedName != null) {
        tz.setLocalLocation(tz.getLocation(matchedName));
      } else {
        final localName = DateTime.now().timeZoneName;
        try {
          tz.setLocalLocation(tz.getLocation(localName));
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
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

      // Create Android Notification Channel with Maximum Priority
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        final channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          showBadge: true,
          enableLights: true,
        );

        await androidImplementation?.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Check if notification permission is currently granted
  Future<bool> isPermissionGranted() async {
    if (kIsWeb) {
      return await WebNotificationManager.instance.isPermissionGranted();
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final areNotificationsEnabled = await androidImplementation?.areNotificationsEnabled();
        return areNotificationsEnabled ?? false;
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }
    return true;
  }

  /// Request permissions with Android 13+, iOS, and Web support
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return await WebNotificationManager.instance.requestPermission();
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        final notifGranted = await androidImplementation?.requestNotificationsPermission();

        try {
          await androidImplementation?.requestExactAlarmsPermission();
        } catch (_) {}

        return notifGranted ?? true;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
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
    String? title,
    String? body,
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
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      sound: androidSound,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      enableLights: true,
      fullScreenIntent: true,
      ticker: 'Task Reminder',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        body ?? '',
        contentTitle: title != null ? '📌 $title' : null,
        summaryText: 'Task Reminder',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> scheduleTaskNotification(Task task, {String sound = 'default', int minutesBefore = 0}) async {
    if (task.id == null || task.isCompleted) return;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      final scheduledTarget = task.dueDate.subtract(Duration(minutes: minutesBefore));
      final now = DateTime.now();

      String bodyText = task.description?.isNotEmpty == true
          ? task.description!
          : 'Task deadline is due now!';

      if (task.subtasks.isNotEmpty) {
        bodyText += ' (${task.completedSubtaskCount}/${task.subtasks.length} subtasks done)';
      }

      // If scheduled time is in the past:
      // If within last 90 seconds (current minute), trigger immediately!
      if (scheduledTarget.isBefore(now)) {
        if (now.difference(scheduledTarget).inSeconds < 90) {
          await showInstantNotification(
            title: '📌 Task Reminder: ${task.title}',
            body: bodyText,
            sound: sound,
          );
        }
        return;
      }

      // WEB PLATFORM SCHEDULING
      if (kIsWeb) {
        _webTimers[task.id!]?.cancel();
        final delay = scheduledTarget.difference(now);
        // Schedule if due within next 7 days
        if (delay.inDays < 7) {
          _webTimers[task.id!] = Timer(delay, () async {
            await showInstantNotification(
              title: '📌 Task Reminder: ${task.title}',
              body: bodyText,
              sound: sound,
            );
          });
        }
        return;
      }

      // NATIVE PLATFORM SCHEDULING (Android/iOS)
      final tzDateTime = tz.TZDateTime(
        tz.local,
        scheduledTarget.year,
        scheduledTarget.month,
        scheduledTarget.day,
        scheduledTarget.hour,
        scheduledTarget.minute,
        scheduledTarget.second,
      );

      final details = _getNotificationDetails(
        soundName: sound,
        title: task.title,
        body: bodyText,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: task.id!,
          title: '📌 Task Reminder: ${task.title}',
          body: bodyText,
          scheduledDate: tzDateTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: task.id.toString(),
        );
      } catch (scheduleError) {
        debugPrint('Exact schedule fallback to inexact: $scheduleError');
        await _notificationsPlugin.zonedSchedule(
          id: task.id!,
          title: '📌 Task Reminder: ${task.title}',
          body: bodyText,
          scheduledDate: tzDateTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelTaskNotification(int taskId) async {
    try {
      if (kIsWeb) {
        _webTimers[taskId]?.cancel();
        _webTimers.remove(taskId);
        return;
      }
      await _notificationsPlugin.cancel(id: taskId);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      if (kIsWeb) {
        for (final timer in _webTimers.values) {
          timer.cancel();
        }
        _webTimers.clear();
        return;
      }
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  Future<bool> showInstantNotification({
    required String title,
    required String body,
    String sound = 'default',
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Trigger in-app floating banner callback if registered
      onInAppNotification?.call(title, body);

      // WEB PLATFORM INSTANT NOTIFICATION
      if (kIsWeb) {
        return await WebNotificationManager.instance.showNotification(
          title: title,
          body: body,
        );
      }

      // NATIVE PLATFORM NOTIFICATION
      await requestPermissions();

      final details = _getNotificationDetails(
        soundName: sound,
        title: title,
        body: body,
      );
      final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
      return false;
    }
  }
}
