import 'web_notification_platform.dart';
import 'web_notification_stub.dart'
    if (dart.library.html) 'web_notification_web.dart';

class WebNotificationManager {
  static final WebNotificationManager instance = WebNotificationManager._();
  final WebNotificationPlatform _platform = getWebNotificationPlatform();

  WebNotificationManager._();

  Future<bool> initialize() => _platform.initialize();
  Future<bool> requestPermission() => _platform.requestPermission();
  Future<bool> isPermissionGranted() => _platform.isPermissionGranted();
  Future<bool> showNotification({
    required String title,
    required String body,
    String? icon,
  }) =>
      _platform.showNotification(title: title, body: body, icon: icon);
  void playNotificationSound() => _platform.playNotificationSound();
}

