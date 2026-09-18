import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import 'legal_document_screen.dart';

class DarkLegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  const DarkLegalDocumentScreen({super.key, required this.document});

  static const _background = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _border = Color(0xFF25344A);
  static const _navy = Color(0xFF102A56);
  static const _blue = Color(0xFF1E4C91);
  static const _violet = Color(0xFF5B36A8);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textMuted = Color(0xFFC4CDDA);

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(document.title),
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentGlassSurface(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _navy.withValues(alpha: 0.82),
                          _blue.withValues(alpha: 0.76),
                          _violet.withValues(alpha: 0.72),
                        ],
                      ),
                      borderColor: Colors.white.withValues(alpha: 0.12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            document.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            document.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...document.sections.map(
                      (section) => StudentGlassSurface(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        borderRadius: BorderRadius.circular(18),
                        tint: _surface.withValues(alpha: 0.58),
                        borderColor: _border.withValues(alpha: 0.72),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.heading,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              section.body,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
