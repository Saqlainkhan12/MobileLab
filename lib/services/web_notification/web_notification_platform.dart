abstract class WebNotificationPlatform {
  Future<bool> initialize();
  Future<bool> requestPermission();
  Future<bool> isPermissionGranted();
  Future<bool> showNotification({
    required String title,
    required String body,
    String? icon,
  });
  void playNotificationSound();
}
