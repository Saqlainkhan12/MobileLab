// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'web_notification_platform.dart';

class WebNotificationPlatformImpl implements WebNotificationPlatform {
  @override
  Future<bool> initialize() async {
    return isPermissionGranted();
  }

  @override
  Future<bool> requestPermission() async {
    if (!html.Notification.supported) return false;
    try {
      final perm = await html.Notification.requestPermission();
      return perm == 'granted';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    if (!html.Notification.supported) return false;
    return html.Notification.permission == 'granted';
  }

  @override
  Future<bool> showNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    if (!html.Notification.supported) return false;

    // Check permission
    if (html.Notification.permission != 'granted') {
      final granted = await requestPermission();
      if (!granted) return false;
    }

    try {
      html.Notification(
        title,
        body: body,
        icon: icon ?? 'favicon.png',
      );
      playNotificationSound();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void playNotificationSound() {
    try {
      final audioContext = html.AudioContext();
      final now = audioContext.currentTime ?? 0;

      // Note 1: High crisp alert chime (880 Hz - A5)
      final osc1 = audioContext.createOscillator();
      final gain1 = audioContext.createGain();
      osc1.type = 'sine';
      osc1.frequency?.setValueAtTime(880, now);
      gain1.gain?.setValueAtTime(0.2, now);
      gain1.gain?.exponentialRampToValueAtTime(0.01, now + 0.18);
      osc1.connect(gain1);
      gain1.connect(audioContext.destination);
      osc1.start(now);
      osc1.stop(now + 0.2);

      // Note 2: Melodic resolution chime (1320 Hz - E6)
      final osc2 = audioContext.createOscillator();
      final gain2 = audioContext.createGain();
      osc2.type = 'sine';
      osc2.frequency?.setValueAtTime(1320, now + 0.15);
      gain2.gain?.setValueAtTime(0.25, now + 0.15);
      gain2.gain?.exponentialRampToValueAtTime(0.001, now + 0.5);
      osc2.connect(gain2);
      gain2.connect(audioContext.destination);
      osc2.start(now + 0.15);
      osc2.stop(now + 0.55);
    } catch (_) {
      // Audio autoplay may be silenced until first user interaction
    }
  }
}

WebNotificationPlatform getWebNotificationPlatform() => WebNotificationPlatformImpl();
