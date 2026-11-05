import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/animated_empty_state.dart';
import '../../widgets/stats_overview_card.dart';
import '../task_detail_screen.dart';

class TodayTasksView extends StatelessWidget {
  final VoidCallback? onAddTask;

  const TodayTasksView({super.key, this.onAddTask});

  static const List<String> _categories = [
    'All',
    'Work',
    'Personal',
    'Study',
    'Health',
    'Finance',
    'General',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.todayTasks;
    final selectedCategory = taskProvider.selectedCategory ?? 'All';

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 84),
      children: [
        // Saqlain Executive Command Card
        const StatsOverviewCard(),

        // Category Quick-Filter Horizontal Strip
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final isSelected = selectedCategory == cat;

              return GestureDetector(
                onTap: () {
                  taskProvider.setCategoryFilter(cat == 'All' ? null : cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : isDark
                            ? const Color(0xFF0F1A24)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : isDark
                              ? const Color(0xFF1B2D3D)
                              : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: isDark ? 0.40 : 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.grey.shade300
                                : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Section Title: Today's Focus
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Priority Agenda",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length} tasks',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Task Cards or Empty State
        if (tasks.isEmpty)
          AnimatedEmptyState(
            icon: Icons.wb_sunny_rounded,
            title: 'No Tasks for Today!',
            subtitle: 'You are all caught up for today. Add a new task to stay organized.',
            actionLabel: 'Add Task for Today',
            onAction: onAddTask,
          )
        else
          ...tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return TaskCard(
              key: ValueKey('today_${task.id}'),
              task: task,
              index: index,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(taskId: task.id!),
                  ),
                );
              },
              onDelete: () {
                taskProvider.deleteTask(task);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "${task.title}" deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => taskProvider.addTask(task),
                    ),
                  ),
                );
              },
            );
          }),
      ],
    );
  }
}
