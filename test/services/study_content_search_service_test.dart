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

    test(
      'searches topic and competency context without flooding results',
      () async {
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
              subtopics: List<StudySubtopic>.generate(
                5,
                (index) => StudySubtopic(
                  id: 'd03_c02_t01_s0${index + 1}',
                  title: 'Method ${index + 1}',
                ),
              ),
            ),
          ],
        );
        final service = StudyContentSearchService(
          loadPublishedContent: () async => <StudyContent>[content],
        );

        final topicResults = await service.search('risk analysis');
        final competencyResults = await service.search('management strategies');

        expect(topicResults, hasLength(2));
        expect(
          topicResults.every((item) => item.matchSection == 'Topic'),
          isTrue,
        );
        expect(competencyResults, hasLength(2));
        expect(
          competencyResults.every((item) => item.matchSection == 'Competency'),
          isTrue,
        );
      },
    );

    test('supports multi-token prefixes for fast learner typing', () async {
      final service = StudyContentSearchService(
        loadPublishedContent: () async => <StudyContent>[_content()],
      );

      final results = await service.search('hier con');

      expect(results, isNotEmpty);
      expect(results.first.subtopicId, 'd03_c02_t01_s01');
      expect(results.first.matchSection, 'Subtopic');
    });

    test('matches compound terms across punctuation differences', () async {
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
            title: 'Energy Control',
            subtopics: <StudySubtopic>[
              StudySubtopic(id: 'd03_c02_t01_s01', title: 'Lock-out/Tag-out'),
            ],
          ),
        ],
      );
      final service = StudyContentSearchService(
        loadPublishedContent: () async => <StudyContent>[content],
      );

      final results = await service.search('lockout');

      expect(results, hasLength(1));
      expect(results.single.subtopicTitle, 'Lock-out/Tag-out');
    });

    test(
      'does not return arbitrary infix-only matches for short terms',
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
              title: 'General',
              subtopics: <StudySubtopic>[
                StudySubtopic(
                  id: 'd03_c02_t01_s01',
                  title: 'The Control Process',
                ),
              ],
            ),
          ],
        );

        final service = StudyContentSearchService(
          loadPublishedContent: () async => <StudyContent>[content],
        );

        expect(await service.search('he'), isEmpty);
      },
    );

    test('honors the requested result limit deterministically', () async {
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
            title: 'Controls',
            subtopics: List<StudySubtopic>.generate(
              6,
              (index) => StudySubtopic(
                id: 'd03_c02_t01_s0${index + 1}',
                title: 'Control method ${index + 1}',
              ),
            ),
          ),
        ],
      );
      final service = StudyContentSearchService(
        loadPublishedContent: () async => <StudyContent>[content],
      );

      final results = await service.search('control', limit: 3);

      expect(results, hasLength(3));
      expect(results.map((item) => item.subtopicId), <String>[
        'd03_c02_t01_s01',
        'd03_c02_t01_s02',
        'd03_c02_t01_s03',
      ]);
    });
  });
}
