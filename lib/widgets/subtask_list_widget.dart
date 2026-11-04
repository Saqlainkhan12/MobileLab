import 'package:flutter/material.dart';
import '../models/subtask.dart';

class SubtaskListWidget extends StatelessWidget {
  final List<Subtask> subtasks;
  final ValueChanged<Subtask>? onToggle;
  final ValueChanged<Subtask>? onDelete;
  final bool isEditable;

  const SubtaskListWidget({
    super.key,
    required this.subtasks,
    this.onToggle,
    this.onDelete,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final completedCount = subtasks.where((s) => s.isCompleted).length;
    final progress = subtasks.isEmpty ? 0.0 : completedCount / subtasks.length;
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rounded, size: 20, color: primary),
                const SizedBox(width: 8),
                Text(
                  'Subtasks (${subtasks.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completedCount/${subtasks.length} Done ($percentage%)',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Animated linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: primary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : primary,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Subtask items list
        if (subtasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'No subtasks added yet.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...subtasks.map((subtask) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                leading: Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: subtask.isCompleted,
                    activeColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: onToggle != null ? (_) => onToggle!(subtask) : null,
                  ),
                ),
                title: Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: subtask.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: subtask.isCompleted
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface,
                  ),
                ),
                trailing: (isEditable && onDelete != null)
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => onDelete!(subtask),
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      )
                    : null,
              ),
            );
          }),
      ],
    );
  }
}
