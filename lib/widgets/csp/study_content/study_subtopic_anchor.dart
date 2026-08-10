import 'package:flutter/material.dart';

class StudySubtopicAnchor extends StatelessWidget {
  final GlobalKey anchorKey;
  final Widget child;

  const StudySubtopicAnchor({
    super.key,
    required this.anchorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(key: anchorKey, child: child);
  }
}
