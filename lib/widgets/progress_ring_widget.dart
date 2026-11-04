import 'package:flutter/material.dart';

class ProgressRingWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool showPercentage;

  const ProgressRingWidget({
    super.key,
    required this.progress,
    this.size = 36,
    this.strokeWidth = 3.5,
    this.color,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final percentage = (progress.clamp(0.0, 1.0) * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: effectiveColor.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            strokeCap: StrokeCap.round,
          ),
          if (showPercentage)
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
            ),
        ],
      ),
    );
  }
}
