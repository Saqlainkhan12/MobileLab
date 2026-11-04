import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/animated_empty_state.dart';
import '../task_detail_screen.dart';

class CompletedTasksView extends StatelessWidget {
  const CompletedTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.completedTasks;

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return const AnimatedEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No Completed Tasks Yet',
        subtitle: 'Complete your daily tasks to see your accomplishments here!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
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

