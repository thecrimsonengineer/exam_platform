import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content_loader.dart';
import '../../../widgets/csp/study_content/study_content_renderer.dart';

class ContentTestScreen extends StatefulWidget {
  const ContentTestScreen({super.key});

  @override
  State<ContentTestScreen> createState() => _ContentTestScreenState();
}

class _ContentTestScreenState extends State<ContentTestScreen> {
  final StudyContentLoader _loader = const StudyContentLoader();

  late Future<StudyContent> _contentFuture;

  @override
  void initState() {
    super.initState();

    _contentFuture = _loader.loadStudyContent(
      domainId: 'domain_07',
      competencyId: 'domain_07_01',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content System Test'),
      ),
      body: FutureBuilder<StudyContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading content:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No content loaded.'),
            );
          }

          final StudyContent content = snapshot.data!;

          return StudyContentRenderer(
            content: content,
          );
        },
      ),
    );
  }
}