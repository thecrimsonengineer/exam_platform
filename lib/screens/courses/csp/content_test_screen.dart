import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../services/study_content_loader.dart';
import 'study_content_screen.dart';

/// Development/student test entry point for the published Study Content path.
///
/// The screen deliberately does not hard-code a competency ID.
/// It loads the first available PUBLISHED competency from the
/// Published Repository and then opens the normal StudyContentScreen.
///
/// This keeps the test path aligned with the repository:
/// Published Repository -> Student Portal.
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
    _loadPublishedTestContent();
  }

  void _loadPublishedTestContent() {
    _contentFuture = _loadFirstPublishedContent();
  }

  Future<StudyContent> _loadFirstPublishedContent() async {
    final published = await _loader.loadPublishedContent();

    if (published.isEmpty) {
      throw StateError(
        'No published study content is available in the Published Repository.',
      );
    }

    final eligible = published
        .where((content) => content.status.toLowerCase() == 'published')
        .toList();

    if (eligible.isEmpty) {
      throw StateError(
        'No content with PUBLISHED status is available in the Published Repository.',
      );
    }

    eligible.sort((a, b) {
      final domainCompare = a.domainId.compareTo(b.domainId);

      if (domainCompare != 0) {
        return domainCompare;
      }

      final competencyCompare = a.competencyNumber.compareTo(
        b.competencyNumber,
      );

      if (competencyCompare != 0) {
        return competencyCompare;
      }

      return b.version.compareTo(a.version);
    });

    return eligible.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudyContent>(
      future: _contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('CSP11 Study Content')),
            body: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 620),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load published study content',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        setState(_loadPublishedTestContent);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final content = snapshot.data;

        if (content == null) {
          return const Scaffold(
            body: Center(
              child: Text('No published study content is available.'),
            ),
          );
        }

        return StudyContentScreen(
          domainId: content.domainId,
          competencyId: content.competencyId,
          loadingTitle: content.title,
        );
      },
    );
  }
}
