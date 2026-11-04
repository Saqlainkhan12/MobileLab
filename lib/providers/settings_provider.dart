import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  int get accentColorIndex => _settings.accentColorIndex;
  String get notificationSound => _settings.notificationSound;
  bool get enableNotifications => _settings.enableNotifications;
  int get reminderMinutesBefore => _settings.reminderMinutesBefore;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final themeMode = themeIndex == 1
        ? ThemeMode.light
        : themeIndex == 2
            ? ThemeMode.dark
            : ThemeMode.system;

    final accentIndex = prefs.getInt('accent_color_index') ?? 0;
    final sound = prefs.getString('notification_sound') ?? 'default';
    final enableNotif = prefs.getBool('enable_notifications') ?? true;
    final reminderMin = prefs.getInt('reminder_minutes') ?? 0;

    _settings = AppSettings(
      themeMode: themeMode,
      accentColorIndex: accentIndex,
      notificationSound: sound,
      enableNotifications: enableNotif,
      reminderMinutesBefore: reminderMin,
    );

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final val = mode == ThemeMode.light ? 1 : (mode == ThemeMode.dark ? 2 : 0);
    await prefs.setInt('theme_mode', val);
  }

  Future<void> setAccentColorIndex(int index) async {
    _settings = _settings.copyWith(accentColorIndex: index);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color_index', index);
  }

  Future<void> setNotificationSound(String sound) async {
    _settings = _settings.copyWith(notificationSound: sound);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', sound);
  }

  Future<void> setEnableNotifications(bool enable) async {
    _settings = _settings.copyWith(enableNotifications: enable);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', enable);
  }

  Future<void> setReminderMinutes(int minutes) async {
    _settings = _settings.copyWith(reminderMinutesBefore: minutes);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
  }
}

