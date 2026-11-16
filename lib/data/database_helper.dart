import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web storage keys and memory cache
  static const String _kWebTasksKey = 'taskflow_web_tasks_storage_v1';
  static const String _kWebSubtasksKey = 'taskflow_web_subtasks_storage_v1';
  static const String _kWebIdCounterKey = 'taskflow_web_id_counter_v1';
  List<Map<String, dynamic>>? _webTasksCache;
  List<Map<String, dynamic>>? _webSubtasksCache;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not used on Flutter Web.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('task_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable Foreign Keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        completed_at TEXT,
        is_repeated INTEGER NOT NULL,
        repeat_type TEXT,
        repeat_days TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        notification_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Create useful indexes for fast queries
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date);');
    await db.execute('CREATE INDEX idx_tasks_is_completed ON tasks(is_completed);');
    await db.execute('CREATE INDEX idx_subtasks_task_id ON subtasks(task_id);');
  }

  // ==================== WEB STORAGE HELPERS ====================

  Future<void> _ensureWebLoaded() async {
    if (_webTasksCache != null && _webSubtasksCache != null) return;

    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_kWebTasksKey);
    if (tasksJson != null) {
      try {
        final decoded = jsonDecode(tasksJson) as List<dynamic>;
        _webTasksCache = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        _webTasksCache = [];
      }
    } else {
      _webTasksCache = [];
    }

    final subtasksJson = prefs.getString(_kWebSubtasksKey);
    if (subtasksJson != null) {
      try {
        final decoded = jsonDecode(subtasksJson) as List<dynamic>;
        _webSubtasksCache = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        _webSubtasksCache = [];
      }
    } else {
      _webSubtasksCache = [];
    }
  }

  Future<void> _saveWebState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWebTasksKey, jsonEncode(_webTasksCache ?? []));
    await prefs.setString(_kWebSubtasksKey, jsonEncode(_webSubtasksCache ?? []));
  }

  // ==================== TASK OPERATIONS ====================

  Future<int> insertTask(Task task) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final prefs = await SharedPreferences.getInstance();
      int nextId = (prefs.getInt(_kWebIdCounterKey) ?? 0) + 1;

      for (final t in _webTasksCache!) {
        final existingId = t['id'] as int?;
        if (existingId != null && existingId >= nextId) {
          nextId = existingId + 1;
        }
      }
      await prefs.setInt(_kWebIdCounterKey, nextId);

      final taskMap = task.toMap();
      taskMap['id'] = nextId;
      _webTasksCache!.add(taskMap);

      for (final subtask in task.subtasks) {
        final stMap = subtask.copyWith(taskId: nextId).toMap();
        _webSubtasksCache!.add(stMap);
      }

      await _saveWebState();
      return nextId;
    }

    final db = await database;
    return await db.transaction((txn) async {
      final taskId = await txn.insert('tasks', task.toMap());
      for (final subtask in task.subtasks) {
        final stMap = subtask.copyWith(taskId: taskId).toMap();
        await txn.insert('subtasks', stMap);
      }
      return taskId;
    });
  }

  Future<int> updateTask(Task task) async {
    if (task.id == null) return 0;

    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webTasksCache!.indexWhere((t) => t['id'] == task.id);
      if (index != -1) {
        final updatedMap = task.toMap();
        updatedMap['id'] = task.id;
        updatedMap['updated_at'] = DateTime.now().toIso8601String();
        _webTasksCache![index] = updatedMap;

        // Refresh subtasks for this task
        _webSubtasksCache!.removeWhere((s) => s['task_id'] == task.id);
        for (final subtask in task.subtasks) {
          final stMap = subtask.copyWith(taskId: task.id).toMap();
          _webSubtasksCache!.add(stMap);
        }

        await _saveWebState();
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.transaction((txn) async {
      final rows = await txn.update(
        'tasks',
        task.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
        where: 'id = ?',
        whereArgs: [task.id],
      );

      // Refresh subtasks
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [task.id]);
      for (final subtask in task.subtasks) {
        final stMap = subtask.copyWith(taskId: task.id).toMap();
        await txn.insert('subtasks', stMap);
      }
      return rows;
    });
  }

  Future<int> deleteTask(int id) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webTasksCache!.removeWhere((t) => t['id'] == id);
      _webSubtasksCache!.removeWhere((s) => s['task_id'] == id);
      await _saveWebState();
      return 1;
    }

    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Task?> getTaskById(int id) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final matches = _webTasksCache!.where((t) => t['id'] == id).toList();
      if (matches.isEmpty) return null;
      final subtasks = await getSubtasksForTask(id);
      return Task.fromMap(matches.first, subtasks: subtasks);
    }

    final db = await database;
    final taskMaps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (taskMaps.isEmpty) return null;

    final subtasks = await getSubtasksForTask(id);
    return Task.fromMap(taskMaps.first, subtasks: subtasks);
  }

  Future<List<Task>> getAllTasks() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final sortedMaps = List<Map<String, dynamic>>.from(_webTasksCache!);
      sortedMaps.sort((a, b) {
        final dateA = DateTime.tryParse(a['due_date'] as String? ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['due_date'] as String? ?? '') ?? DateTime.now();
        final comp = dateA.compareTo(dateB);
        if (comp != 0) return comp;
        return (b['priority'] as String? ?? '').compareTo(a['priority'] as String? ?? '');
      });
      return await _populateTasksWithSubtasks(sortedMaps);
    }

    final db = await database;
    final taskMaps = await db.query('tasks', orderBy: 'due_date ASC, priority DESC');
    return await _populateTasksWithSubtasks(taskMaps);
  }

  Future<List<Task>> getTodayTasks() async {
    if (kIsWeb) {
      final all = await getAllTasks();
      return all.where((t) => t.isDueToday).toList();
    }

    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final taskMaps = await db.query(
      'tasks',
      where: 'due_date >= ? AND due_date <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'is_completed ASC, due_date ASC',
    );
    return await _populateTasksWithSubtasks(taskMaps);
  }

  Future<List<Task>> getCompletedTasks() async {
    if (kIsWeb) {
      final all = await getAllTasks();
      return all.where((t) => t.isCompleted).toList();
    }

    final db = await database;
    final taskMaps = await db.query(
      'tasks',
      where: 'is_completed = 1',
      orderBy: 'completed_at DESC, updated_at DESC',
    );
    return await _populateTasksWithSubtasks(taskMaps);
  }

  Future<List<Task>> getRepeatedTasks() async {
    if (kIsWeb) {
      final all = await getAllTasks();
      return all.where((t) => t.isRepeated).toList();
    }

    final db = await database;
    final taskMaps = await db.query(
      'tasks',
      where: 'is_repeated = 1',
      orderBy: 'due_date ASC',
    );
    return await _populateTasksWithSubtasks(taskMaps);
  }

  Future<List<Task>> _populateTasksWithSubtasks(List<Map<String, dynamic>> taskMaps) async {
    if (taskMaps.isEmpty) return [];

    final tasks = <Task>[];
    for (final map in taskMaps) {
      final taskId = map['id'] as int;
      final subtasks = await getSubtasksForTask(taskId);
      tasks.add(Task.fromMap(map, subtasks: subtasks));
    }
    return tasks;
  }

  // ==================== SUBTASK OPERATIONS ====================

  Future<List<Subtask>> getSubtasksForTask(int taskId) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final matches = _webSubtasksCache!
          .where((s) => s['task_id'] == taskId)
          .map((s) => Subtask.fromMap(s))
          .toList();
      matches.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return matches;
    }

    final db = await database;
    final subtaskMaps = await db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'created_at ASC',
    );
    return subtaskMaps.map((s) => Subtask.fromMap(s)).toList();
  }

  Future<int> updateSubtaskStatus(String subtaskId, bool isCompleted) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webSubtasksCache!.indexWhere((s) => s['id'] == subtaskId);
      if (index != -1) {
        _webSubtasksCache![index]['is_completed'] = isCompleted ? 1 : 0;
        await _saveWebState();
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'subtasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
  }
}
