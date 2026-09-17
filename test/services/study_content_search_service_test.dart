import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/study_content_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

StudyContent _content() {
  return const StudyContent(
    id: 'd03_c02-v1',
    domainId: 'd03',
    competencyId: 'd03_c02',
    competencyNumber: 2,
    title: 'Risk Management Strategies',
    status: 'Published',
    version: 1,
    topics: <StudyTopic>[
      StudyTopic(
        id: 'd03_c02_t01',
        title: 'Risk Analysis',
        subtopics: <StudySubtopic>[
          StudySubtopic(
            id: 'd03_c02_t01_s01',
            title: 'Hierarchy of Controls',
            learningObjectives: <String>[
              'Explain how elimination and substitution reduce risk.',
            ],
            blocks: <ContentBlock>[
              ContentBlock(
                id: 'block-1',
                type: 'text',
                data: <String, dynamic>{
                  'heading': 'Bow-tie analysis',
                  'body':
                      'Bow-tie analysis links preventive controls to threats '
                      'and recovery controls to consequences.',
                },
              ),
            ],
            keyPoints: <String>[
              'Engineering controls reduce reliance on worker behaviour.',
            ],
            examTips: <String>[
              'Distinguish elimination from administrative controls.',
            ],
          ),
          StudySubtopic(
            id: 'd03_c02_t01_s02',
            title: 'Job Hazard Analysis',
            blocks: <ContentBlock>[
              ContentBlock(
                id: 'block-2',
                type: 'text',
                data: <String, dynamic>{
                  'body':
                      'Break the job into steps before identifying hazards '
                      'and selecting controls.',
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('StudyContentSearchService', () {
    test('matches subtopic titles and returns exact navigation IDs', () async {
      final service = StudyContentSearchService(
        loadPublishedContent: () async => <StudyContent>[_content()],
      );

      final results = await service.search('hierarchy');

      expect(results, isNotEmpty);
      expect(results.first.domainId, 'd03');
      expect(results.first.competencyId, 'd03_c02');
      expect(results.first.topicId, 'd03_c02_t01');
      expect(results.first.subtopicId, 'd03_c02_t01_s01');
      expect(results.first.matchSection, 'Subtopic');
    });

    test('matches text inside visible content block data', () async {
      final service = StudyContentSearchService(
        loadPublishedContent: () async => <StudyContent>[_content()],
      );

      final results = await service.search('preventive controls');

      expect(results, hasLength(1));
      expect(results.single.subtopicId, 'd03_c02_t01_s01');
      expect(results.single.matchSection, 'Main content');
      expect(results.single.snippet.toLowerCase(), contains('preventive'));
    });

    test('matches supplemental learner-facing sections', () async {
      final service = StudyContentSearchService(
        loadPublishedContent: () async => <StudyContent>[_content()],
      );

      final results = await service.search('worker behaviour');

      expect(results, hasLength(1));
      expect(results.single.matchSection, 'Key point');
    });

    test('requires at least two normalized characters', () async {
      var calls = 0;
      final service = StudyContentSearchService(
        loadPublishedContent: () async {
          calls++;
          return <StudyContent>[_content()];
        },
      );

      expect(await service.search('a'), isEmpty);
      expect(calls, 0);
    });

    test(
      'normalizes chemical subscripts for ordinary keyboard searches',
      () async {
        final content = StudyContent(
          id: 'd03_c02-v1',
          domainId: 'd03',
          competencyId: 'd03_c02',
          competencyNumber: 2,
          title: 'Risk Management Strategies',
          status: 'Published',
          version: 1,
          topics: const <StudyTopic>[
            StudyTopic(
              id: 'd03_c02_t01',
              title: 'Chemical Hazards',
              subtopics: <StudySubtopic>[
                StudySubtopic(
                  id: 'd03_c02_t01_s03',
                  title: 'Hydrogen Sulfide',
                  keyPoints: <String>[
                    'H₂S can accumulate in poorly ventilated low points.',
                  ],
                ),
              ],
            ),
          ],
        );

        final service = StudyContentSearchService(
          loadPublishedContent: () async => <StudyContent>[content],
        );

        final results = await service.search('H2S');

        expect(results, hasLength(1));
        expect(results.single.subtopicId, 'd03_c02_t01_s03');
      },
    );

    test('reuses the in-memory index across repeated searches', () async {
      var calls = 0;
      final service = StudyContentSearchService(
        loadPublishedContent: () async {
          calls++;
          return <StudyContent>[_content()];
        },
      );

      await service.search('hierarchy');
      await service.search('hazard');
      await service.search('controls');

      expect(calls, 1);
    });

    test('ranks a direct subtopic-title match above body text', () async {
      final content = StudyContent(
        id: 'd03_c02-v1',
        domainId: 'd03',
        competencyId: 'd03_c02',
        competencyNumber: 2,
        title: 'Risk Management Strategies',
        status: 'Published',
        version: 1,
        topics: <StudyTopic>[
          StudyTopic(
            id: 'd03_c02_t01',
            title: 'Risk Analysis',
            subtopics: <StudySubtopic>[
              const StudySubtopic(
                id: 'd03_c02_t01_s01',
                title: 'Permit to Work',
              ),
              StudySubtopic(
                id: 'd03_c02_t01_s02',
                title: 'Administrative Systems',
                blocks: const <ContentBlock>[
                  ContentBlock(
                    id: 'block',
                    type: 'text',
                    data: <String, dynamic>{
                      'body': 'A permit to work can control hazardous tasks.',
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final service = StudyContentSearchService(
        loadPublishedContent: () async => <StudyContent>[content],
      );

      final results = await service.search('permit to work');

      expect(results, hasLength(2));
      expect(results.first.subtopicId, 'd03_c02_t01_s01');
      expect(results.first.matchSection, 'Subtopic');
    });
  });
}
