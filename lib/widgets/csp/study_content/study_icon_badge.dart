import 'package:flutter/material.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';

class StudyIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final bool showBorder;
  final bool showShadow;

  const StudyIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.size = 44,
    this.iconSize = 21,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor ?? color.withValues(alpha: 0.10);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: StudyRadius.medium,
        border: showBorder
            ? Border.all(color: color.withValues(alpha: 0.12))
            : null,
        boxShadow: showShadow ? StudyShadows.soft : null,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
