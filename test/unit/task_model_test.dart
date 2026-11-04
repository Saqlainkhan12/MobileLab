import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_lab/models/task.dart';
import 'package:mobile_lab/models/subtask.dart';
import 'package:mobile_lab/models/repeat_config.dart';

void main() {
  group('Task Model Serialization Tests', () {
    test('Task correctly converts to map and restores from map', () {
      final now = DateTime(2026, 11, 4, 12, 0);
      final subtasks = [
        Subtask(id: 'st-1', taskId: 10, title: 'Item 1', isCompleted: true),
      ];

      final originalTask = Task(
        id: 10,
        title: 'Review Assignment',
        description: 'Complete rubric verification',
        dueDate: now,
        priority: TaskPriority.high,
        category: 'Study',
        isCompleted: false,
        repeatConfig: const RepeatConfig(type: RepeatType.weekly, selectedDays: [1, 3, 5]),
        createdAt: now,
        updatedAt: now,
        subtasks: subtasks,
      );

      final map = originalTask.toMap();
      expect(map['id'], 10);
      expect(map['title'], 'Review Assignment');
      expect(map['priority'], 'high');
      expect(map['category'], 'Study');
      expect(map['is_repeated'], 1);
      expect(map['repeat_type'], 'weekly');

      final reconstructedTask = Task.fromMap(map, subtasks: subtasks);
      expect(reconstructedTask.id, originalTask.id);
      expect(reconstructedTask.title, originalTask.title);
      expect(reconstructedTask.priority, TaskPriority.high);
      expect(reconstructedTask.category, 'Study');
      expect(reconstructedTask.repeatConfig.type, RepeatType.weekly);
      expect(reconstructedTask.repeatConfig.selectedDays, [1, 3, 5]);
      expect(reconstructedTask.subtasks.length, 1);
      expect(reconstructedTask.subtasks.first.title, 'Item 1');
    });

    test('Priority parsing handles fallbacks safely', () {
      expect(TaskPriority.fromString('high'), TaskPriority.high);
      expect(TaskPriority.fromString('low'), TaskPriority.low);
      expect(TaskPriority.fromString('unknown'), TaskPriority.medium);
      expect(TaskPriority.fromString(null), TaskPriority.medium);
    });
  });
}

