import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import 'study_content_screen.dart';

/// Development/student test entry point for the targeted StudyContent path.
///
/// FR10E deliberately uses the canonical blueprint to select a structural
/// competency. Opening StudyContentScreen then exercises the normal
/// Firebase-authorized competency package path. No broad published-content
/// query is performed by this screen.
class ContentTestScreen extends StatelessWidget {
  const ContentTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final domain = csp11Domains.first;
    final competency = domain.competencies.first;

    return StudyContentScreen(
      domainId: domain.id,
      competencyId: competency.id,
      domainTitle: domain.title,
      loadingTitle: 'Competency ${competency.number}',
    );
  }
}
