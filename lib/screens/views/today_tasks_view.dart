import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/animated_empty_state.dart';
import '../task_detail_screen.dart';

class TodayTasksView extends StatelessWidget {
  final VoidCallback? onAddTask;

  const TodayTasksView({super.key, this.onAddTask});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.todayTasks;

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return AnimatedEmptyState(
        icon: Icons.wb_sunny_rounded,
        title: 'No Tasks for Today!',
        subtitle: 'You are all caught up for today. Add a new task to stay organized.',
        actionLabel: 'Add Task for Today',
        onAction: onAddTask,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
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
      },
    );
  }
}
