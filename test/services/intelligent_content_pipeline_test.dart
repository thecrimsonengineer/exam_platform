import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/models/source_extraction_result.dart';
import 'package:exam_platform/services/study_content/content_repository_service.dart';
import 'package:exam_platform/services/study_content/intelligent_content_pipeline_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    '44.4L: complete intelligent pipeline creates and persists a CSP11 draft',
    () async {
      const sourceText = '''
3. Risk Management

3.1 Risk Assessment

Risk assessment is a systematic process used to identify hazards,
evaluate risks, and determine appropriate controls.

3.2 Risk Mitigation

Risk management strategies should be applied to identify and mitigate
EHS hazards.

3.3 Risk Analysis

Risk analysis involves identifying, ranking, and monitoring risks.
''';

      final extraction = SourceExtractionResult.successResult(
        sourceId: 'test_source_44_4l',
        fileName: 'complete-pipeline-test.txt',
        mimeType: 'text/plain',
        extractedText: sourceText,
        pageCount: 1,
        pages: [const ExtractedSourcePage(pageNumber: 1, text: sourceText)],
      );

      final pipeline = IntelligentContentPipelineService();

      // SOURCE -> ANALYSIS
      final analysis = pipeline.analyzeSource(extraction: extraction);

      expect(analysis.sourceId, 'test_source_44_4l');

      expect(analysis.nodes, isNotEmpty);

      expect(analysis.candidates, isNotEmpty);

      // ANALYSIS -> VALID CSP11 CANDIDATE
      final candidate = analysis.candidates.first;

      expect(candidate.sourceId, 'test_source_44_4l');

      expect(candidate.domainId, isNotEmpty);

      expect(candidate.competencyId, isNotNull);

      expect(candidate.confidence, greaterThan(0));

      expect(candidate.confidence, lessThanOrEqualTo(1));

      expect(candidate.evidenceTerms, isNotEmpty);

      // CANDIDATE -> SOURCE NODE
      final sourceNode = analysis.nodes.firstWhere(
        (node) => node.text.trim().isNotEmpty || node.title.trim().isNotEmpty,
      );

      // SOURCE NODE -> GENERATED DRAFT
      final draft = await pipeline.createDraftFromCandidate(
        candidate: candidate,
        sourceNode: sourceNode,
      );

      expect(draft.id, isNotEmpty);

      expect(draft.status.toLowerCase(), 'draft');

      expect(draft.version, 1);

      expect(draft.domainId, candidate.domainId);

      expect(draft.competencyId, candidate.competencyId);

      expect(draft.competencyNumber, greaterThan(0));

      expect(draft.title, isNotEmpty);

      expect(draft.subtopics, isNotEmpty);

      final subtopic = draft.subtopics.first;

      expect(subtopic.mainContent, isNotEmpty);

      final topic = subtopic.mainContent.first;

      expect(topic.blocks, isNotEmpty);

      final block = topic.blocks.first;

      final generatedContent = block.data['content']?.toString() ?? '';

      expect(generatedContent, isNotEmpty);

      expect(generatedContent.toLowerCase(), contains('risk'));

      // GENERATED DRAFT -> REPOSITORY
      final repository = ContentRepositoryService();

      final packages = await repository.loadPackages();

      expect(packages, isNotEmpty);

      final savedPackage = packages.firstWhere(
        (package) => package.content.id == draft.id,
      );

      final saved = savedPackage.content;

      expect(saved.id, draft.id);

      expect(saved.status.toLowerCase(), 'draft');

      expect(saved.version, 1);

      expect(saved.domainId, draft.domainId);

      expect(saved.competencyId, draft.competencyId);

      expect(saved.competencyNumber, draft.competencyNumber);

      expect(saved.subtopics, isNotEmpty);

      expect(saved.subtopics.first.mainContent, isNotEmpty);

      expect(saved.subtopics.first.mainContent.first.blocks, isNotEmpty);

      expect(savedPackage.isPublishedCopy, isFalse);
    },
  );
}
