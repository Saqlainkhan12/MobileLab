import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Map<String, String>> _notificationSounds = [
    {'id': 'default', 'label': 'System Default'},
    {'id': 'gentle_chime', 'label': 'Gentle Chime'},
    {'id': 'modern_bell', 'label': 'Modern Bell'},
    {'id': 'urgent_alert', 'label': 'Urgent Alert'},
  ];

  static const List<Map<String, dynamic>> _reminderOffsets = [
    {'minutes': 0, 'label': 'At time of task'},
    {'minutes': 15, 'label': '15 minutes before'},
    {'minutes': 30, 'label': '30 minutes before'},
    {'minutes': 60, 'label': '1 hour before'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Customization'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Section 1: Appearance & Theme
          _buildSectionHeader(context, 'Theme & Appearance', Icons.palette_rounded),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {settingsProvider.themeMode},
                    onSelectionChanged: (val) {
                      settingsProvider.setThemeMode(val.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Accent Color Scheme',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(AppTheme.palettes.length, (index) {
                      final palette = AppTheme.palettes[index];
                      final isSelected = settingsProvider.accentColorIndex == index;

                      return GestureDetector(
                        onTap: () => settingsProvider.setAccentColorIndex(index),
                        child: Tooltip(
                          message: palette.name,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [palette.primary, palette.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: palette.primary.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Notifications & Reminders
          _buildSectionHeader(context, 'Notifications & Alerts', Icons.notifications_active_rounded),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Receive alerts for upcoming deadlines'),
                    value: settingsProvider.enableNotifications,
                    activeThumbColor: primary,
                    onChanged: (val) => settingsProvider.setEnableNotifications(val),
                  ),
                  const Divider(height: 20),

                  // Notification Sound Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alert Sound', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Choose reminder tone', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      DropdownButton<String>(
                        value: settingsProvider.notificationSound,
                        underline: const SizedBox(),
                        items: _notificationSounds.map((sound) {
                          return DropdownMenuItem(
                            value: sound['id'],
                            child: Text(sound['label']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) settingsProvider.setNotificationSound(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Reminder Time Offset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Remind Me', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Time offset before due date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      DropdownButton<int>(
                        value: settingsProvider.reminderMinutesBefore,
                        underline: const SizedBox(),
                        items: _reminderOffsets.map((offset) {
                          return DropdownMenuItem<int>(
                            value: offset['minutes'] as int,
                            child: Text(offset['label'] as String),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) settingsProvider.setReminderMinutes(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Test notification button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await NotificationService.instance.showInstantNotification(
                          title: 'TaskFlow Notification Test',
                          body: 'Your notification system is fully working!',
                          sound: settingsProvider.notificationSound,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test notification sent! Check notification tray.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.ring_volume_rounded, size: 18),
                      label: const Text('Send Test Notification'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: App Information
          _buildSectionHeader(context, 'About Application', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.verified_rounded, color: Colors.blue),
                    title: Text('TaskFlow Mobile Lab App'),
                    subtitle: Text('Version 1.0.0 • Flutter + SQLite Architecture'),
                  ),
                  Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.storage_rounded, color: Colors.teal),
                    title: Text('Storage Engine'),
                    subtitle: Text('SQLite Persistent Relational Database'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
