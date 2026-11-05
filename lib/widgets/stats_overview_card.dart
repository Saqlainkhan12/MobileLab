import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'progress_ring_widget.dart';

class StatsOverviewCard extends StatelessWidget {
  const StatsOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;

    final taskProvider = context.watch<TaskProvider>();
    final total = taskProvider.totalCount;
    final completed = taskProvider.completedCount;
    final progress = taskProvider.overallProgress;
    final today = taskProvider.todayCount;
    final repeated = taskProvider.repeatedCount;
    final percentage = (progress * 100).round();

    String greeting;
    if (percentage == 100 && total > 0) {
      greeting = 'All tasks completed! Amazing work 🎉';
    } else if (percentage >= 50) {
      greeting = 'You are crushing your goals! 🚀';
    } else if (total > 0) {
      greeting = 'Stay focused and get things done 💡';
    } else {
      greeting = 'Welcome to TaskFlow! Tap + to start 🚀';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                  const Color(0xFF0F172A),
                ]
              : [
                  primary.withValues(alpha: 0.12),
                  secondary.withValues(alpha: 0.04),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Progress Ring & Status Message
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ProgressRingWidget(
                  progress: progress,
                  size: 64,
                  strokeWidth: 6,
                  color: percentage == 100 ? const Color(0xFF10B981) : primary,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Productivity Score',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              color: primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      greeting,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: theme.dividerColor.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 14),

          // 4 Metric Badges Grid
          Row(
            children: [
              _buildMetricCard(
                context,
                title: 'Today',
                value: '$today',
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                context,
                title: 'Done',
                value: '$completed',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                context,
                title: 'Repeat',
                value: '$repeated',
                icon: Icons.sync_rounded,
                color: primary,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                context,
                title: 'Total',
                value: '$total',
                icon: Icons.layers_rounded,
                color: const Color(0xFF06B6D4),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.18),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
