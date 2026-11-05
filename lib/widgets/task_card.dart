import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'priority_badge.dart';
import 'category_chip.dart';
import 'progress_ring_widget.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.index = 0,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isOverdue = task.isOverdue;
    final isHighPriority = task.priority == TaskPriority.high && !task.isCompleted;

    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task?'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        onDelete?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: task.isCompleted
                ? Colors.green.withValues(alpha: 0.4)
                : (isOverdue
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : (isHighPriority
                        ? primary.withValues(alpha: 0.35)
                        : theme.dividerColor.withValues(alpha: 0.4))),
            width: task.isCompleted || isOverdue || isHighPriority ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighPriority
                  ? primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Checkbox, Title, Priority
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Checkbox
                      GestureDetector(
                        onTap: () {
                          context.read<TaskProvider>().toggleTaskCompletion(task);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: task.isCompleted ? Colors.green : Colors.transparent,
                            border: Border.all(
                              color: task.isCompleted
                                  ? Colors.green
                                  : primary.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: task.isCompleted
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: task.isCompleted
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                  .animate()
                                  .scale(duration: 250.ms, curve: Curves.easeOutBack)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: task.isCompleted
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                                    : theme.colorScheme.onSurface,
                              ),
                              child: Text(task.title),
                            ),
                            if (task.description?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Priority Badge
                      PriorityBadge(priority: task.priority, compact: true),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Subtask Progress Bar (if task has subtasks)
                  if (task.subtasks.isNotEmpty) ...[
                    Row(
                      children: [
                        ProgressRingWidget(
                          progress: task.progress,
                          size: 24,
                          strokeWidth: 2.8,
                          showPercentage: false,
                          color: task.progress == 1.0 ? Colors.green : primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtasks: ${task.completedSubtaskCount}/${task.subtaskCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  Text(
                                    '${task.progressPercentage}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: task.progress == 1.0 ? Colors.green : primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  tween: Tween<double>(begin: 0, end: task.progress),
                                  builder: (context, value, _) {
                                    return LinearProgressIndicator(
                                      value: value,
                                      minHeight: 4,
                                      backgroundColor: primary.withValues(alpha: 0.12),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        value == 1.0 ? Colors.green : primary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Bottom Row: Category, Due Date, Repeat Badge
                  Row(
                    children: [
                      CategoryChip(category: task.category),
                      const Spacer(),

                      // Repeat icon if repeated
                      if (task.isRepeated) ...[
                        Tooltip(
                          message: task.repeatConfig.summaryText,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: primary,
                            ),
                          ),
                        ),
                      ],

                      // Due Date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? theme.colorScheme.error.withValues(alpha: 0.12)
                              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                              size: 13,
                              color: isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(task.dueDate),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                                color: isOverdue
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 350.ms,
          delay: (index * 45).clamp(0, 350).ms,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 350.ms,
          delay: (index * 45).clamp(0, 350).ms,
        );
  }
}
