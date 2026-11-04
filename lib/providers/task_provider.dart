import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/repeat_config.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  TaskPriority? _selectedPriority;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  TaskPriority? get selectedPriority => _selectedPriority;

  // Filtered views as per requirement
  List<Task> get allTasks => _applyFilters(_tasks);

  List<Task> get todayTasks => _applyFilters(
        _tasks.where((t) => t.isDueToday && !t.isCompleted).toList(),
      );

  List<Task> get completedTasks => _applyFilters(
        _tasks.where((t) => t.isCompleted).toList(),
      );

  List<Task> get repeatedTasks => _applyFilters(
        _tasks.where((t) => t.isRepeated).toList(),
      );

  List<Task> get overdueTasks => _applyFilters(
        _tasks.where((t) => t.isOverdue).toList(),
      );

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get todayCount => _tasks.where((t) => t.isDueToday && !t.isCompleted).length;
  int get repeatedCount => _tasks.where((t) => t.isRepeated).length;

  double get overallProgress {
    if (_tasks.isEmpty) return 0.0;
    return completedCount / _tasks.length;
  }

  TaskProvider() {
    loadTasks();
  }

  // ==================== LOAD & FILTER ====================

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _dbHelper.getAllTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPriority = null;
    notifyListeners();
  }

  List<Task> _applyFilters(List<Task> source) {
    return source.where((task) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(q);
        final matchesDesc = task.description?.toLowerCase().contains(q) ?? false;
        final matchesCategory = task.category.toLowerCase().contains(q);
        if (!matchesTitle && !matchesDesc && !matchesCategory) return false;
      }

      if (_selectedCategory != null && _selectedCategory != 'All') {
        if (task.category.toLowerCase() != _selectedCategory!.toLowerCase()) {
          return false;
        }
      }

      if (_selectedPriority != null) {
        if (task.priority != _selectedPriority) return false;
      }

      return true;
    }).toList();
  }

  // ==================== CRUD OPERATIONS ====================

  Future<void> loadSampleData() async {
    final now = DateTime.now();

    final sample1 = Task(
      title: 'Complete Mobile Lab Assignment',
      description: 'Implement Flutter UI, SQLite Database, and Notification System.',
      dueDate: DateTime(now.year, now.month, now.day, 20, 0),
      priority: TaskPriority.high,
      category: 'Study',
      subtasks: [
        Subtask(title: 'Set up Flutter & SQLite Database', isCompleted: true),
        Subtask(title: 'Implement Task Management CRUD', isCompleted: true),
        Subtask(title: 'Add Repeat & Progress Tracking', isCompleted: true),
        Subtask(title: 'Export to PDF, CSV & Email', isCompleted: false),
      ],
    );

    final sample2 = Task(
      title: 'Morning Fitness Routine',
      description: 'Daily morning exercise and stretching session.',
      dueDate: DateTime(now.year, now.month, now.day, 7, 30),
      priority: TaskPriority.medium,
      category: 'Health',
      repeatConfig: const RepeatConfig(type: RepeatType.daily),
      subtasks: [
        Subtask(title: '15 min cardio warmup', isCompleted: true),
        Subtask(title: 'Core workouts & pushups', isCompleted: false),
        Subtask(title: 'Cool down & hydration', isCompleted: false),
      ],
    );

    final sample3 = Task(
      title: 'Team Project Status Meeting',
      description: 'Weekly team sync on Mon, Wed, Fri.',
      dueDate: DateTime(now.year, now.month, now.day, 14, 0),
      priority: TaskPriority.medium,
      category: 'Work',
      repeatConfig: const RepeatConfig(type: RepeatType.weekly, selectedDays: [1, 3, 5]),
      subtasks: [
        Subtask(title: 'Prepare progress slides', isCompleted: false),
        Subtask(title: 'Review submitted PRs', isCompleted: false),
      ],
    );

    final sample4 = Task(
      title: 'Submit Project APK & Documentation',
      description: 'Submitted all code, README guide, and debug APK.',
      dueDate: DateTime(now.year, now.month, now.day, 18, 0),
      priority: TaskPriority.high,
      category: 'Study',
      isCompleted: true,
      completedAt: now,
      subtasks: [
        Subtask(title: 'Build debug APK', isCompleted: true),
        Subtask(title: 'Prepare video demonstration guide', isCompleted: true),
      ],
    );

    await addTask(sample1);
    await addTask(sample2);
    await addTask(sample3);
    await addTask(sample4);
  }

  Future<int> addTask(Task task, {String sound = 'default', int reminderMinutes = 0}) async {
    try {
      final id = await _dbHelper.insertTask(task);
      final newTask = task.copyWith(id: id);

      if (!newTask.isCompleted) {
        await _notificationService.scheduleTaskNotification(
          newTask,
          sound: sound,
          minutesBefore: reminderMinutes,
        );
      }

      await loadTasks();
      return id;
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task, {String sound = 'default', int reminderMinutes = 0}) async {
    try {
      await _dbHelper.updateTask(task);

      if (task.id != null) {
        await _notificationService.cancelTaskNotification(task.id!);
        if (!task.isCompleted) {
          await _notificationService.scheduleTaskNotification(
            task,
            sound: sound,
            minutesBefore: reminderMinutes,
          );
        }
      }

      await loadTasks();
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(Task task) async {
    if (task.id == null) return;
    try {
      await _dbHelper.deleteTask(task.id!);
      await _notificationService.cancelTaskNotification(task.id!);
      await loadTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    if (task.id == null) return;

    final newStatus = !task.isCompleted;

    if (newStatus && task.isRepeated) {
      await _handleRepeatedTaskCompletion(task);
    } else {
      final updatedTask = task.copyWith(
        isCompleted: newStatus,
        completedAt: newStatus ? DateTime.now() : null,
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> _handleRepeatedTaskCompletion(Task task) async {
    DateTime nextDueDate = calculateNextDueDate(task.dueDate, task.repeatConfig);

    // If the task was overdue, catch up to the next upcoming occurrence
    final now = DateTime.now();
    int guard = 0;
    while (nextDueDate.isBefore(now) && guard < 50) {
      nextDueDate = calculateNextDueDate(nextDueDate, task.repeatConfig);
      guard++;
    }

    final resetSubtasks = task.subtasks.map((s) => s.copyWith(isCompleted: false)).toList();

    final nextTask = task.copyWith(
      dueDate: nextDueDate,
      isCompleted: false,
      completedAt: null,
      subtasks: resetSubtasks,
      updatedAt: DateTime.now(),
    );

    await _dbHelper.updateTask(nextTask);
    if (nextTask.id != null) {
      await _notificationService.cancelTaskNotification(nextTask.id!);
      await _notificationService.scheduleTaskNotification(nextTask);
    }

    await loadTasks();
  }

  static DateTime calculateNextDueDate(DateTime currentDue, RepeatConfig config) {
    switch (config.type) {
      case RepeatType.daily:
        return DateTime(
          currentDue.year,
          currentDue.month,
          currentDue.day + 1,
          currentDue.hour,
          currentDue.minute,
        );

      case RepeatType.weekly:
        if (config.selectedDays.isEmpty) {
          return currentDue.add(const Duration(days: 7));
        }

        // Find next day of the week in selectedDays (1 = Mon, ..., 7 = Sun)
        for (int i = 1; i <= 7; i++) {
          final candidate = currentDue.add(Duration(days: i));
          if (config.selectedDays.contains(candidate.weekday)) {
            return DateTime(
              candidate.year,
              candidate.month,
              candidate.day,
              currentDue.hour,
              currentDue.minute,
            );
          }
        }
        return currentDue.add(const Duration(days: 7));

      case RepeatType.monthly:
        int nextMonth = currentDue.month + 1;
        int nextYear = currentDue.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        final maxDaysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final safeDay = currentDue.day > maxDaysInMonth ? maxDaysInMonth : currentDue.day;
        return DateTime(
          nextYear,
          nextMonth,
          safeDay,
          currentDue.hour,
          currentDue.minute,
        );

      case RepeatType.none:
        return currentDue;
    }
  }

  // ==================== SUBTASK ACTIONS ====================

  Future<void> toggleSubtask(Task task, Subtask subtask) async {
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtask.id) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    final allDone = updatedSubtasks.every((s) => s.isCompleted);

    final updatedTask = task.copyWith(
      subtasks: updatedSubtasks,
      isCompleted: allDone && updatedSubtasks.isNotEmpty ? true : task.isCompleted,
      completedAt: allDone && updatedSubtasks.isNotEmpty ? (task.completedAt ?? DateTime.now()) : null,
    );

    await updateTask(updatedTask);
  }
}
