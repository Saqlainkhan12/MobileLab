import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/animated_empty_state.dart';
import '../../widgets/stats_overview_card.dart';
import '../task_detail_screen.dart';

class AllTasksView extends StatelessWidget {
  final VoidCallback? onAddTask;

  const AllTasksView({super.key, this.onAddTask});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.allTasks;

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const StatsOverviewCard(),
        if (tasks.isEmpty)
          AnimatedEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Tasks Found',
            subtitle: taskProvider.searchQuery.isNotEmpty
                ? 'Try searching with a different keyword or filter.'
                : 'Get started by creating your first task!',
            actionLabel: 'Create Task',
            onAction: onAddTask,
          )
        else
          ...tasks.map((task) {
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
          }),
      ],
    );
  }
}

