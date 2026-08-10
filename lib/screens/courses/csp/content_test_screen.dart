import 'package:flutter/material.dart';

import 'study_content_screen.dart';

class ContentTestScreen extends StatelessWidget {
  const ContentTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudyContentScreen(
      domainId: 'domain_07',
      competencyId: 'domain_07_01',
      loadingTitle: 'CSP11 Study Content',
    );
  }
}
