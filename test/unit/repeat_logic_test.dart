import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_lab/models/repeat_config.dart';
import 'package:mobile_lab/models/subtask.dart';
import 'package:mobile_lab/models/task.dart';
import 'package:mobile_lab/providers/task_provider.dart';

void main() {
  group('Task Progress Calculation Tests', () {
    test('Task without subtasks has 0% progress when incomplete and 100% when completed', () {
      final task = Task(
        id: 1,
        title: 'Complete assignment',
        dueDate: DateTime.now(),
        isCompleted: false,
      );

      expect(task.progress, 0.0);
      expect(task.progressPercentage, 0);

      final completedTask = task.copyWith(isCompleted: true);
      expect(completedTask.progress, 1.0);
      expect(completedTask.progressPercentage, 100);
    });

    test('Task with subtasks calculates exact progress percentage', () {
      final subtasks = [
        Subtask(title: 'Step 1', isCompleted: true),
        Subtask(title: 'Step 2', isCompleted: false),
        Subtask(title: 'Step 3', isCompleted: true),
        Subtask(title: 'Step 4', isCompleted: false),
      ];

      final task = Task(
        id: 2,
        title: 'Project research',
        dueDate: DateTime.now(),
        subtasks: subtasks,
      );

      expect(task.subtaskCount, 4);
      expect(task.completedSubtaskCount, 2);
      expect(task.progress, 0.5);
      expect(task.progressPercentage, 50);
    });
  });

  group('Repeat Logic Calculation Tests', () {
    test('Daily repeat calculation correctly advances by 1 day', () {
      final initialDate = DateTime(2026, 11, 4, 10, 30);
      const config = RepeatConfig(type: RepeatType.daily);

      final nextDate = TaskProvider.calculateNextDueDate(initialDate, config);
      expect(nextDate.year, 2026);
      expect(nextDate.month, 11);
      expect(nextDate.day, 5);
      expect(nextDate.hour, 10);
      expect(nextDate.minute, 30);
    });

    test('Weekly repeat calculation advances to next scheduled weekday', () {
      // 2026-11-04 is a Wednesday (weekday 3)
      final wednesday = DateTime(2026, 11, 4, 15, 0);
      // Repeat on Friday (weekday 5) and Monday (weekday 1)
      const config = RepeatConfig(
        type: RepeatType.weekly,
        selectedDays: [1, 5],
      );

      final nextDate = TaskProvider.calculateNextDueDate(wednesday, config);
      // Next occurrence after Wednesday (3) in [1, 5] should be Friday (5) -> 2026-11-06
      expect(nextDate.weekday, DateTime.friday);
      expect(nextDate.day, 6);
      expect(nextDate.hour, 15);
      expect(nextDate.minute, 0);
    });

    test('Monthly repeat calculation advances by 1 month', () {
      final initialDate = DateTime(2026, 1, 15, 9, 0);
      const config = RepeatConfig(type: RepeatType.monthly);

      final nextDate = TaskProvider.calculateNextDueDate(initialDate, config);
      expect(nextDate.year, 2026);
      expect(nextDate.month, 2);
      expect(nextDate.day, 15);
      expect(nextDate.hour, 9);
      expect(nextDate.minute, 0);
    });
  });
}

