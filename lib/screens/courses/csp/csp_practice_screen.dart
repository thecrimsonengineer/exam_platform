import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../widgets/csp/student_quiz_builder.dart';

class CspPracticeScreen extends StatelessWidget {
  final String title;
  final String description;

  const CspPracticeScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StudentGlassSurface(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  borderRadius: BorderRadius.circular(18),

                  tint: Colors.white.withValues(alpha: 0.50),

                  borderColor: const Color(0xFFE3E8F0).withValues(alpha: 0.72),
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF596477),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const StudentQuizBuilder(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
