import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/glass/student_glass.dart';

import '../../../models/progress_analytics_snapshot.dart';

class ProgressPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ProgressPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StudentGlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: scheme.surface.withValues(alpha: 0.54),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.42),
      shadowColor: scheme.shadow.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class WeeklyActivityLineChart extends StatelessWidget {
  final List<ProgressDailyActivity> values;

  const WeeklyActivityLineChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final labels = values.map((item) => _weekday(item.dateKey)).toList();

    return SizedBox(
      height: 190,
      child: CustomPaint(
        painter: _WeeklyActivityPainter(
          values: values.map((item) => item.minutes.toDouble()).toList(),
          labels: labels,
          color: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
          textColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  String _weekday(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) {
      return '';
    }

    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }
}

class _WeeklyActivityPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color gridColor;
  final Color textColor;

  _WeeklyActivityPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 28.0;

    final chartWidth = math.max(1.0, size.width - left - right);
    final chartHeight = math.max(1.0, size.height - top - bottom);
    final maxValue = values.isEmpty
        ? 1.0
        : math.max(1.0, values.reduce((a, b) => a > b ? a : b));

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    if (values.isEmpty) {
      return;
    }

    final line = Path();
    final fill = Path();

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (values.length - 1);
      final y = top + chartHeight * (1 - values[i] / maxValue);

      if (i == 0) {
        line.moveTo(x, y);
        fill.moveTo(x, top + chartHeight);
        fill.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }

    final lastX = values.length == 1
        ? left + chartWidth / 2
        : left + chartWidth;
    fill
      ..lineTo(lastX, top + chartHeight)
      ..close();

    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.09));

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (values.length - 1);
      final y = top + chartHeight * (1 - values[i] / maxValue);

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);

      _drawText(
        canvas,
        labels.length > i ? labels[i] : '',
        Offset(x, top + chartHeight + 8),
        textColor,
        center: true,
      );
    }

    _drawText(canvas, '${maxValue.round()}m', const Offset(0, top), textColor);
    _drawText(canvas, '0m', Offset(8, top + chartHeight - 6), textColor);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = center ? offset.dx - painter.width / 2 : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.textColor != textColor;
  }
}

class DomainProgressBars extends StatelessWidget {
  final List<ProgressDomainAnalyticsSummary> domains;

  const DomainProgressBars({super.key, required this.domains});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: domains
          .map((domain) {
            final percentage = (domain.progress * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      'D${domain.domainNumber.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: domain.progress,
                        minHeight: 10,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '$percentage%',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class CompletionBars extends StatelessWidget {
  final int completedDomains;
  final int totalDomains;
  final int completedTopics;
  final int totalTopics;
  final int completedSubtopics;
  final int totalSubtopics;

  const CompletionBars({
    super.key,
    required this.completedDomains,
    required this.totalDomains,
    required this.completedTopics,
    required this.totalTopics,
    required this.completedSubtopics,
    required this.totalSubtopics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(context, 'Domains', completedDomains, totalDomains),
        const SizedBox(height: 14),
        _row(context, 'Topics', completedTopics, totalTopics),
        const SizedBox(height: 14),
        _row(context, 'Subtopics', completedSubtopics, totalSubtopics),
      ],
    );
  }

  Widget _row(BuildContext context, String label, int completed, int total) {
    final value = total == 0 ? 0.0 : completed / total;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: Text(
            '$completed/$total',
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class AccuracyDonut extends StatelessWidget {
  final double accuracy;
  final int answered;
  final int correct;

  const AccuracyDonut({
    super.key,
    required this.accuracy,
    required this.answered,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percentage = (accuracy * 100).round();

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: CustomPaint(
          painter: _DonutPainter(
            progress: accuracy,
            color: scheme.tertiary,
            background: scheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$correct / $answered correct',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color background;

  _DonutPainter({
    required this.progress,
    required this.color,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = math.min(size.width, size.height) * 0.075;

    final bg = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(stroke), -math.pi / 2, math.pi * 2, false, bg);
    canvas.drawArc(
      rect.deflate(stroke),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.background != background;
  }
}

class WeeklyActivityHeatmap extends StatelessWidget {
  final List<ProgressDailyActivity> values;

  const WeeklyActivityHeatmap({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxSeconds = values.isEmpty
        ? 1
        : math.max(
            1,
            values.map((item) => item.seconds).reduce((a, b) => a > b ? a : b),
          );

    return Row(
      children: values
          .map((item) {
            final intensity = item.seconds / maxSeconds;
            final date = DateTime.tryParse(item.dateKey);
            final label = date == null
                ? ''
                : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(
                          alpha: item.seconds == 0
                              ? 0.07
                              : 0.16 + 0.70 * intensity,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
