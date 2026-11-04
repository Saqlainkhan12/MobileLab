import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/repeat_config.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/repeat_selector_dialog.dart';
import '../widgets/subtask_list_widget.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AddEditTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  final TextEditingController _subtaskController = TextEditingController();

  late DateTime _selectedDueDate;
  late TimeOfDay _selectedDueTime;
  late TaskPriority _selectedPriority;
  late String _selectedCategory;
  late RepeatConfig _repeatConfig;
  late List<Subtask> _subtasks;

  final List<String> _categories = [
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
    final edit = widget.taskToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _descController = TextEditingController(text: edit?.description ?? '');

    if (edit != null) {
      _selectedDueDate = DateTime(edit.dueDate.year, edit.dueDate.month, edit.dueDate.day);
      _selectedDueTime = TimeOfDay(hour: edit.dueDate.hour, minute: edit.dueDate.minute);
      _selectedPriority = edit.priority;
      _selectedCategory = edit.category;
      _repeatConfig = edit.repeatConfig;
      _subtasks = List.from(edit.subtasks);
    } else {
      final now = DateTime.now();
      _selectedDueDate = DateTime(now.year, now.month, now.day);
      _selectedDueTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
      _selectedPriority = TaskPriority.medium;
      _selectedCategory = 'General';
      _repeatConfig = const RepeatConfig();
      _subtasks = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime,
    );
    if (picked != null) {
      setState(() => _selectedDueTime = picked);
    }
  }

  Future<void> _configureRepeat() async {
    final result = await showDialog<RepeatConfig>(
      context: context,
      builder: (_) => RepeatSelectorDialog(initialConfig: _repeatConfig),
    );
    if (result != null) {
      setState(() => _repeatConfig = result);
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subtasks.add(Subtask(title: text));
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(Subtask st) {
    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == st.id);
      if (index != -1) {
        _subtasks[index] = st.copyWith(isCompleted: !st.isCompleted);
      }
    });
  }

  void _deleteSubtask(Subtask st) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == st.id);
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final dueDateTime = DateTime(
      _selectedDueDate.year,
      _selectedDueDate.month,
      _selectedDueDate.day,
      _selectedDueTime.hour,
      _selectedDueTime.minute,
    );

    final settings = context.read<SettingsProvider>().settings;

    final task = (widget.taskToEdit ?? Task(
      title: _titleController.text.trim(),
      dueDate: dueDateTime,
    )).copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      dueDate: dueDateTime,
      priority: _selectedPriority,
      category: _selectedCategory,
      repeatConfig: _repeatConfig,
      subtasks: _subtasks,
      updatedAt: DateTime.now(),
    );

    final taskProvider = context.read<TaskProvider>();
    if (widget.taskToEdit == null) {
      await taskProvider.addTask(
        task,
        sound: settings.notificationSound,
        reminderMinutes: settings.reminderMinutesBefore,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );
      }
    } else {
      await taskProvider.updateTask(
        task,
        sound: settings.notificationSound,
        reminderMinutes: settings.reminderMinutesBefore,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully!')),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isEditing = widget.taskToEdit != null;

    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 28),
            onPressed: _saveTask,
            tooltip: 'Save Task',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                hintText: 'What needs to be done?',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add notes or details...',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // Due Date & Time Section
            Text(
              'Due Date & Time',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      dateFormat.format(_selectedDueDate),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 18),
                    label: Text(
                      _selectedDueTime.format(context),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 120.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // Repeat Settings Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repeat Task',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _configureRepeat,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Configure'),
                ),
              ],
            ).animate().fadeIn(delay: 150.ms),
            InkWell(
              onTap: _configureRepeat,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _repeatConfig.isRepeated
                      ? primary.withValues(alpha: 0.08)
                      : theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _repeatConfig.isRepeated
                        ? primary.withValues(alpha: 0.4)
                        : theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _repeatConfig.isRepeated ? Icons.repeat_rounded : Icons.repeat_one_rounded,
                      color: _repeatConfig.isRepeated ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _repeatConfig.summaryText,
                        style: TextStyle(
                          color: _repeatConfig.isRepeated ? primary : theme.colorScheme.onSurface,
                          fontWeight: _repeatConfig.isRepeated ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 170.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // Priority Selector
            Text(
              'Priority',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                Color color;
                switch (priority) {
                  case TaskPriority.high:
                    color = AppTheme.priorityHigh;
                    break;
                  case TaskPriority.medium:
                    color = AppTheme.priorityMedium;
                    break;
                  case TaskPriority.low:
                    color = AppTheme.priorityLow;
                    break;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPriority = priority),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : color.withValues(alpha: 0.4),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          priority.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 220.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // Category Selector
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 240.ms),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final catColor = AppTheme.categoryColors[cat] ?? primary;
                final catIcon = AppTheme.categoryIcons[cat] ?? Icons.label_outline_rounded;

                return ChoiceChip(
                  avatar: Icon(
                    catIcon,
                    size: 16,
                    color: isSelected ? Colors.white : catColor,
                  ),
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: catColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                );
              }).toList(),
            ).animate().fadeIn(delay: 260.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),

            // Subtasks Section (Progress Tracking)
            SubtaskListWidget(
              subtasks: _subtasks,
              onToggle: _toggleSubtask,
              onDelete: _deleteSubtask,
              isEditable: true,
            ).animate().fadeIn(delay: 280.ms, duration: 300.ms),
            const SizedBox(height: 8),

            // Add Subtask input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: InputDecoration(
                      hintText: 'Add a subtask...',
                      prefixIcon: const Icon(Icons.add_task_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add Subtask',
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton.icon(
              onPressed: _saveTask,
              icon: Icon(isEditing ? Icons.check_circle_rounded : Icons.add_task_rounded),
              label: Text(
                isEditing ? 'Save Changes' : 'Create Task',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ).animate().fadeIn(delay: 320.ms).scale(duration: 250.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
