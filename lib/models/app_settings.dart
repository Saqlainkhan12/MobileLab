import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final int accentColorIndex;
  final String notificationSound;
  final bool enableNotifications;
  final int reminderMinutesBefore;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColorIndex = 0,
    this.notificationSound = 'default',
    this.enableNotifications = true,
    this.reminderMinutesBefore = 0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? accentColorIndex,
    String? notificationSound,
    bool? enableNotifications,
    int? reminderMinutesBefore,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      notificationSound: notificationSound ?? this.notificationSound,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }
}

