import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../widgets/csp/student_quiz_builder.dart';

class DarkCspPracticeScreen extends StatelessWidget {
  final String title;
  final String description;

  const DarkCspPracticeScreen({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A111D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A111D),
          foregroundColor: const Color(0xFFF4F7FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111B2C),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF25344A)),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFC4CDDA),
                        fontSize: 12,
                        height: 1.55,
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
      ),
    );
  }
}
