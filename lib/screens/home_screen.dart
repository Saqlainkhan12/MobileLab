import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'add_edit_task_screen.dart';
import 'settings_screen.dart';
import 'views/today_tasks_view.dart';
import 'views/completed_tasks_view.dart';
import 'views/repeated_tasks_view.dart';
import 'views/all_tasks_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Work',
    'Personal',
    'Study',
    'Health',
    'Finance',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto prompt notification permission on Android 13+
      NotificationService.instance.requestPermissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTaskScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditTaskScreen(),
      ),
    );
  }

  void _showColorPickerModal(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.palettes[settings.accentColorIndex.clamp(0, AppTheme.palettes.length - 1)].primary,
                          AppTheme.palettes[settings.accentColorIndex.clamp(0, AppTheme.palettes.length - 1)].secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.palette_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Saqlain's Color Theme",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Switch vibrant executive color palettes across TaskFlow:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppTheme.palettes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pal = entry.value;
                  final isSelected = settings.accentColorIndex == idx;

                  return GestureDetector(
                    onTap: () {
                      settings.setAccentColorIndex(idx);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? pal.primary.withValues(alpha: isDark ? 0.28 : 0.15)
                            : isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? pal.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [pal.primary, pal.secondary]),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pal.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? pal.primary : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final selectedCategory = taskProvider.selectedCategory ?? 'All';
            final selectedPriority = taskProvider.selectedPriority;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Tasks',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          taskProvider.clearFilters();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            taskProvider.setCategoryFilter(cat == 'All' ? null : cat);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Priority',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Priorities'),
                        selected: selectedPriority == null,
                        onSelected: (s) {
                          if (s) {
                            taskProvider.setPriorityFilter(null);
                            setModalState(() {});
                          }
                        },
                      ),
                      ...TaskPriority.values.map((p) {
                        final isSelected = selectedPriority == p;
                        return ChoiceChip(
                          label: Text(p.displayName),
                          selected: isSelected,
                          onSelected: (s) {
                            if (s) {
                              taskProvider.setPriorityFilter(p);
                              setModalState(() {});
                            }
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final taskProvider = context.watch<TaskProvider>();

    final hasActiveFilter = taskProvider.selectedCategory != null ||
        taskProvider.selectedPriority != null ||
        taskProvider.searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      taskProvider.setSearchQuery('');
                      setState(() => _isSearching = false);
                    },
                  ),
                ),
                onChanged: (val) {
                  taskProvider.setSearchQuery(val);
                },
              )
            : Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: primary,
                          child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .shimmer(duration: 2500.ms, color: Colors.white.withValues(alpha: 0.35))
                      .scale(begin: const Offset(0.97, 0.97), end: const Offset(1.03, 1.03), duration: 2000.ms),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Task',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.3,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Flow',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.3,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Saqlain's Command Studio",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          if (!_isSearching) ...[
            // Quick Theme Palette Switcher
            IconButton(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              tooltip: 'Color Palette',
              onPressed: () => _showColorPickerModal(context),
            ),
            // Instant Heads-Up Notification Tester
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
              tooltip: 'Test Alert Notification',
              onPressed: () async {
                await NotificationService.instance.showInstantNotification(
                  title: 'TaskFlow Active',
                  body: 'Salam Saqlain! Heads-up reminder notifications are active!',
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: primary,
                    content: const Text('📌 Notification sent! Check your top notification bar.'),
                  ),
                );
              },
            ),
            // Light / Dark Mode Toggle
            IconButton(
              icon: Icon(
                theme.brightness == Brightness.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              tooltip: theme.brightness == Brightness.dark ? 'Light Mode' : 'Dark Mode',
              onPressed: () {
                final sp = context.read<SettingsProvider>();
                final next = theme.brightness == Brightness.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
                sp.setThemeMode(next);
              },
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearching = true),
            ),
          ],
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilter,
              smallSize: 8,
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: 'Filter',
            onPressed: () => _showFilterModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: primary,
          indicatorWeight: 3,
          labelColor: primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('Today'),
                  if (taskProvider.todayCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(taskProvider.todayCount, Colors.orange),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Completed'),
                  if (taskProvider.completedCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(taskProvider.completedCount, Colors.green),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Repeated'),
                  if (taskProvider.repeatedCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(taskProvider.repeatedCount, primary),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('All Tasks'),
                  if (taskProvider.totalCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(taskProvider.totalCount, Colors.blueGrey),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter status pill bar (if filters are active)
          if (hasActiveFilter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered: ${[
                        if (taskProvider.selectedCategory != null)
                          'Category: ${taskProvider.selectedCategory}',
                        if (taskProvider.selectedPriority != null)
                          'Priority: ${taskProvider.selectedPriority!.displayName}',
                        if (taskProvider.searchQuery.isNotEmpty)
                          '"${taskProvider.searchQuery}"',
                      ].join(' • ')}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      taskProvider.clearFilters();
                      setState(() => _isSearching = false);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TodayTasksView(onAddTask: _openAddTaskScreen),
                const CompletedTasksView(),
                RepeatedTasksView(onAddTask: _openAddTaskScreen),
                AllTasksView(onAddTask: _openAddTaskScreen),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _openAddTaskScreen,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.03, 1.03),
            duration: 1800.ms,
            curve: Curves.easeInOut,
          ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
