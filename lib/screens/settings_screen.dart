import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _isNotificationPermitted;

  static const List<Map<String, String>> _notificationSounds = [
    {'id': 'default', 'label': 'System Default'},
    {'id': 'gentle_chime', 'label': 'Gentle Chime'},
    {'id': 'modern_bell', 'label': 'Modern Bell'},
    {'id': 'urgent_alert', 'label': 'Urgent Alert'},
  ];

  static const List<Map<String, dynamic>> _reminderOffsets = [
    {'minutes': 0, 'label': 'At time of task'},
    {'minutes': 15, 'label': '15 min before'},
    {'minutes': 30, 'label': '30 min before'},
    {'minutes': 60, 'label': '1 hr before'},
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.isPermissionGranted();
    if (mounted) {
      setState(() => _isNotificationPermitted = granted);
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.instance.requestPermissions();
    if (mounted) {
      setState(() => _isNotificationPermitted = granted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted
              ? 'Notification permission granted!'
              : 'Permission was not granted. Please enable it in Device Settings.'),
          backgroundColor: granted ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Customization'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // Section 1: Appearance & Theme
          _buildSectionHeader(context, 'Theme & Appearance', Icons.palette_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Mode',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded, size: 18),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded, size: 18),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded, size: 18),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {settingsProvider.themeMode},
                    onSelectionChanged: (val) {
                      settingsProvider.setThemeMode(val.first);
                    },
                  ),
                ),
                const SizedBox(height: 22),
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
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [palette.primary, palette.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: palette.primary.withValues(alpha: 0.6),
                                      blurRadius: 14,
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 22)
                                  .animate()
                                  .scale(duration: 200.ms)
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
          const SizedBox(height: 24),

          // Section 2: Notifications & Reminders (BUG-FREE & RESPONSIVE)
          _buildSectionHeader(context, 'Notifications & Alerts', Icons.notifications_active_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permission Status Banner
                if (_isNotificationPermitted == false) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Notifications not permitted by Android system.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                          ),
                        ),
                        TextButton(
                          onPressed: _requestNotificationPermission,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(50, 30),
                          ),
                          child: const Text('Allow', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Switch row
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('Receive alerts for scheduled deadlines', style: TextStyle(fontSize: 12)),
                  value: settingsProvider.enableNotifications,
                  activeThumbColor: primary,
                  onChanged: (val) async {
                    await settingsProvider.setEnableNotifications(val);
                    if (val) {
                      await _requestNotificationPermission();
                    }
                  },
                ),
                const Divider(height: 20),

                // Alert Sound Dropdown (Responsive - NO OVERFLOW)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alert Sound', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            'Choose reminder tone',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: settingsProvider.notificationSound,
                          isDense: true,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: primary),
                          items: _notificationSounds.map((sound) {
                            return DropdownMenuItem(
                              value: sound['id'],
                              child: Text(
                                sound['label']!,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) settingsProvider.setNotificationSound(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Remind Me Offset Dropdown (Responsive - NO OVERFLOW)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Remind Me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            'Time offset before due date',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: settingsProvider.reminderMinutesBefore,
                          isDense: true,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: primary),
                          items: _reminderOffsets.map((offset) {
                            return DropdownMenuItem<int>(
                              value: offset['minutes'] as int,
                              child: Text(
                                offset['label'] as String,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) settingsProvider.setReminderMinutes(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Test notification button with high visibility
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final success = await NotificationService.instance.showInstantNotification(
                        title: '🔔 TaskFlow Alert',
                        body: 'Your notification system is fully active and working!',
                        sound: settingsProvider.notificationSound,
                      );
                      await _checkPermission();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Alert sent! Swipe down your status bar to see it.'
                                : 'Failed to display notification. Please grant permission.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.ring_volume_rounded, size: 20),
                    label: const Text('Send Test Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.08, end: 0),
          const SizedBox(height: 24),

          // Section 3: App Information
          _buildSectionHeader(context, 'About Application', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.verified_rounded, color: Colors.blue, size: 28),
                      ),
                    ),
                  ),
                  title: const Text('TaskFlow Mobile Lab App', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Version 1.0.0 • Flutter + SQLite Architecture'),
                ),
                const Divider(),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.storage_rounded, color: Colors.teal, size: 28),
                  title: Text('Storage Engine', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SQLite Persistent Relational Database'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<TaskProvider>().loadSampleData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample tasks loaded! Check Today, Repeated & Completed tabs.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
                    label: const Text('Load Demo / Sample Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.08, end: 0),
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: primary),
        ),
        const SizedBox(width: 10),
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
