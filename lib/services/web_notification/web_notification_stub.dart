import 'web_notification_platform.dart';

class WebNotificationPlatformImpl implements WebNotificationPlatform {
  @override
  Future<bool> initialize() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> isPermissionGranted() async => false;

  @override
  Future<bool> showNotification({
    required String title,
    required String body,
    String? icon,
  }) async => false;

  @override
  void playNotificationSound() {}
}

WebNotificationPlatform getWebNotificationPlatform() => WebNotificationPlatformImpl();

