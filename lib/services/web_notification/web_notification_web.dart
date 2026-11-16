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
      final audio = html.AudioElement();
      audio.src =
          'data:audio/wav;base64,UklGRvQHAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YdAHAAB/1u+/cT4/X3l+gpi5wplNFB9tx+3KfkU9WnZ+gJKywqNcHRpdt+nSjE09VXJ+f42rwKtrKBhOp+LZmVc+UG99f4ikvbF4MxhCl9rdpWFBTGp8f4WduLWFQBs4hs/fsW1ESWZ7f4KXs7iQTSAwd8Pfu3hKR2F4foGSrrmaWicqaLbcw4RQRl12foCNqLiiZy8nW6jYypBYRllyfn+JoraoczkmT5rRzpthSFVvfX+FnLKsf0MnRozJ0aVqS1JrfH+Dlq6viU4rPn6/0q50T1Bnen6BkaqwklowOHK00bZ+VE5jeH6AjaSwmWU2NGapzb2IWk5gdn5/iZ+vn3A+M1udycGSYU9cc35/hpqtpHpHM1KQwsWbaVFZcH1/g5Wpp4NQNUqEusakcVRXbHx/gZGmqYtaOER5scareldWaXp+gI2hqZNkPUBuqMSxg1xVZXh+f4mdqZhtRD5knsG2i2JVYnZ+f4aZp512Sz1ck7y6k2lWYHN9f4SUpaB/Uz5UibW8m3BYXXB9f4KQoqKGW0BPfq68ondbXG17foCMnqONY0RKdaa7qH5fW2p6fn+Jm6OSbElHbJ65rIZkW2h4fn+Gl6KXdE9GZJW1sI1pW2V2fn+Ek6Gae1VGXYyxspRvXGNzfX+Cj56dglxIWIOrtJp1X2FxfH+BjJueiGNLU3qks6B7YmBue36AiZiejWtOUHKdsqSCZWBsen5/hpWeknJTTmuWr6iIaWBqeH5/hJKdlXhYTmWOrKqObmFodn5/go+bmH9eT1+Gp6yUc2JmdH1/gYyZmYRkUVt+oqyZeWRlcnx+gImWmolqU1h3nKydfmdkcHt+f4aTmo1wV1ZxlqqhhGtkbnp+f4SRmZF2W1Vrj6ejiW5kbHh+f4KOmJN8YFVmiKSljnNlanZ+f4GLlpWBZVZigp+mk3dnaXR9f4CIlJaGalhee5qml3xpaHN8fn+GkpaKcFtcdZWlmoFsaHF7fn+Ej5aNdV5bcJCjnYVvaG96fn+DjZWPemJba4qgn4pyaG54fn+BipSRf2ZbZ4SdoI52aWx3fX+AiJKSg2tcZH6ZoJJ6a2t1fX6AhpCThnBeYnmUoJV+bWtzfH5/hI6TiXRhYHSQn5iDcGtye35/g4ySjHlkYHCLnZqGc2txen5/gYqRjn1oYGyGmpuKdmxveH5/gIiQj4BsYWmBl5yOeW1ud31/gIaOkIRwYmd8k5yRfW9udn1+f4SNkId0ZGV4j5uTgHFudHx+f4OLkIl3Z2R0i5mVhHNuc3t+f4KJj4t7aWRwh5eXh3Zucnp+f4GHjox/bWRtg5WXinhvcXl+f4CGjY2CcGVrfpKYjXtwcHd9fn+Ei46Ec2dpe4+Xj35ycHZ9fn+Dio2Hd2lod4uWkYF0cHV8fn+CiI2IemtodIiVk4R2cHR7fn+Bh4yKfW5ocYSTlId4cXN6fn+AhYuLgHFob4CRlIp7cnN5fn9/hIqLgnRpbX2OlIx9c3J4fX5/g4mLhXZrbHqLk46AdHJ3fX5/goiLhnlta3eIko+CdnJ2fH5/gYaLiHxva3SFkZCFeHJ1e35/gIWKiX9xa3KCj5GHenN1en5/f4SJiYF0bHB+jZGJfHR0eX5+f4OIioN2bW98ipGLfnV0eH1+f4KHioV5bm55iJCMgXZ0eH1+f4GGiYZ7cG53hY+Ng3h0d3x+f4CFiYd9cm50go6OhXp0dnt+f4CEiIiAdG5zgIyOh3x1dnp+f3+Dh4iBdm9xfYqOiH12dXp9fn+ChoiDeXBxe4iOin93dXl9fn+BhYiEe3FweYWNi4F4dXh9fn+AhIiFfXNwd4OMjIN6dXh8fn+Ag4eGf3VwdYGLjIV7dnd7fn9/goaHgHdxdH6JjIZ9d3d7fn5/goaHgnhxc3yHjIh+d3d6fX5/gYWHg3pzcnqFjImAeHZ5fX5/gISHhHx0cnmDi4qCend5fX5/gIOGhX51cneBioqDe3d4fH5/f4KGhX93cnZ/iIqFfHd4e35/f4KFhoF4c3V+h4qGfnh4e35+f4GEhoJ6dHR8hYqHf3l4en1+f4CEhoN8dXR6hImIgXp4en1+f4CDhYR9dnR5gomIgnt4eX1+f3+ChYR/d3R4gIiJg3x4eXx+f3+BhISAeXR3foaJhH15eXx+fn+BhIWBenV2fYWJhX55eXt+fn+Ag4WCe3Z1e4SIhoB6eXt9fn+Ag4SDfXd1eoKIh4F7eXp9fn9/goSDfnh1eYGHh4J8eXp9fn9/gYSDf3l1eH+Gh4N9eXp8fn9/gYOEgHp2d36Fh4R+enl8fn5/gIOEgXt3d3yEh4V/enl7fn5/gIKEgnx3d3uCh4WAe3l7fX5/f4KDgn14dnqBhoaBfHp7fX5/f4GDg395d3mAhYaCfXp6fX5/f4GDg396d3l+hIaDfnp6fH5+f4CCg4B7d3h9g4aEfnt6fH5+f4CCg4F8eHh8goaEf3t6fH5+f3+Bg4F9eXh7gYWFgHx6e31+f3+Bg4J+eXh6gIWFgX16e31+f3+BgoJ/enh6f4SFgn17e31+f3+AgoKAe3h5foOFg357e31+fn+AgoKAfHl5fYKFg397e3x+fn9/gYKBfXl5fIGEhIB8e3x+fn9/gYKBfnp5e4CEhIB9e3x9fn9/gIKCf3t5e3+DhIF9e3x9fn9/gIKCf3t5eg==';
      audio.play().catchError((_) {});
    } catch (_) {}
  }
}

WebNotificationPlatform getWebNotificationPlatform() => WebNotificationPlatformImpl();

