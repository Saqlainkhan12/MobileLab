import 'repeat_config.dart';
import 'subtask.dart';

enum TaskPriority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  static TaskPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}

class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final TaskPriority priority;
  final String category;
  final bool isCompleted;
  final DateTime? completedAt;
  final RepeatConfig repeatConfig;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? notificationId;
  final List<Subtask> subtasks;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.category = 'General',
    this.isCompleted = false,
    this.completedAt,
    this.repeatConfig = const RepeatConfig(),
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notificationId,
    this.subtasks = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isRepeated => repeatConfig.isRepeated;

  int get subtaskCount => subtasks.length;
  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;

  double get progress {
    if (subtasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    return completedSubtaskCount / subtasks.length;
  }

  int get progressPercentage => (progress * 100).round();

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return taskDay.isBefore(today);
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? category,
    bool? isCompleted,
    DateTime? completedAt,
    RepeatConfig? repeatConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? notificationId,
    List<Subtask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      repeatConfig: repeatConfig ?? this.repeatConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationId: notificationId ?? this.notificationId,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'priority': priority.name,
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'is_repeated': repeatConfig.isRepeated ? 1 : 0,
      'repeat_type': repeatConfig.type.name,
      'repeat_days': repeatConfig.daysJson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notification_id': notificationId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, {List<Subtask> subtasks = const []}) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['due_date'] as String),
      priority: TaskPriority.fromString(map['priority'] as String?),
      category: (map['category'] as String?) ?? 'General',
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      repeatConfig: RepeatConfig(
        type: RepeatType.fromString(map['repeat_type'] as String?),
        selectedDays: RepeatConfig.parseDaysJson(map['repeat_days'] as String?),
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      notificationId: map['notification_id'] as int?,
      subtasks: subtasks,
    );
  }
}

