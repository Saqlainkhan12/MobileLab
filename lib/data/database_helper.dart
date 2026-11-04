import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
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

  // ==================== TASK OPERATIONS ====================

  Future<int> insertTask(Task task) async {
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
    final db = await database;
    if (task.id == null) return 0;

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
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final taskMaps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (taskMaps.isEmpty) return null;

    final subtasks = await getSubtasksForTask(id);
    return Task.fromMap(taskMaps.first, subtasks: subtasks);
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final taskMaps = await db.query('tasks', orderBy: 'due_date ASC, priority DESC');
    return await _populateTasksWithSubtasks(taskMaps);
  }

  Future<List<Task>> getTodayTasks() async {
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
    final db = await database;
    final taskMaps = await db.query(
      'tasks',
      where: 'is_completed = 1',
      orderBy: 'completed_at DESC, updated_at DESC',
    );
    return await _populateTasksWithSubtasks(taskMaps);
  }

  Future<List<Task>> getRepeatedTasks() async {
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
    final db = await database;

    final tasks = <Task>[];
    for (final map in taskMaps) {
      final taskId = map['id'] as int;
      final subtaskMaps = await db.query(
        'subtasks',
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'created_at ASC',
      );
      final subtasks = subtaskMaps.map((s) => Subtask.fromMap(s)).toList();
      tasks.add(Task.fromMap(map, subtasks: subtasks));
    }
    return tasks;
  }

  // ==================== SUBTASK OPERATIONS ====================

  Future<List<Subtask>> getSubtasksForTask(int taskId) async {
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
    final db = await database;
    return await db.update(
      'subtasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

