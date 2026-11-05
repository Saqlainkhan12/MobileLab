import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
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

    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMM d').format(now);
    final hour = now.hour;

    String timeGreeting;
    if (hour >= 5 && hour < 12) {
      timeGreeting = 'Subah Bakhair! Ready to conquer your day?';
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = 'Keep up the strong momentum today!';
    } else if (hour >= 17 && hour < 21) {
      timeGreeting = 'Shaam Bakhair! Reviewing your daily achievements.';
    } else {
      timeGreeting = 'Reviewing your productivity tonight.';
    }

    String motivationTag;
    if (percentage == 100 && total > 0) {
      motivationTag = 'All Tasks Conquered 🎉';
    } else if (percentage >= 50) {
      motivationTag = '$percentage% Crushing Goals 🚀';
    } else if (total > 0) {
      motivationTag = '$percentage% In Motion ⚡';
    } else {
      motivationTag = 'Ready to Plan ✨';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0D1B1E), // Deep Cyber Obsidian
                  const Color(0xFF071412),
                ]
              : [
                  primary.withValues(alpha: 0.14),
                  secondary.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.40 : 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.25 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Personalized Salutation & Date Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASLAM O ALAIKUM SAQLAIN! 👋',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeGreeting,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: primary),
                    const SizedBox(width: 5),
                    Text(
                      dateString,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: theme.dividerColor.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 16),

          // Row 2: Radial Productivity Gauge & Motivation
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.30),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ProgressRingWidget(
                  progress: progress,
                  size: 66,
                  strokeWidth: 6.5,
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
                          'Productivity Level',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              color: primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      motivationTag,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Row 3: 4 Bento Metric Badges Grid
          Row(
            children: [
              _buildMetricCard(
                context,
                title: 'Today',
                value: '$today',
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFF59E0B), // Sunset Amber
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                context,
                title: 'Done',
                value: '$completed',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981), // Emerald Jade
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                context,
                title: 'Repeat',
                value: '$repeated',
                icon: Icons.sync_rounded,
                color: const Color(0xFF8B5CF6), // Royal Amethyst
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                context,
                title: 'Total',
                value: '$total',
                icon: Icons.layers_rounded,
                color: const Color(0xFF06B6D4), // Electric Cyan
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
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.30 : 0.20),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
