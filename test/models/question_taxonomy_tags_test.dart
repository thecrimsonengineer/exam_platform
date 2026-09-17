import 'package:exam_platform/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

Question _question({
  int domain = 7,
  String competencyId = 'd07_c02',
  String topicId = 'd07_c02_03_t01',
  String subtopicId = 'd07_c02_03',
  List<String> tags = const <String>['risk control', 'hierarchy of controls'],
}) {
  return Question(
    id: 1,
    domain: domain,
    competencyId: competencyId,
    subtopicId: subtopicId,
    topicId: topicId,
    quizId: 'quiz-1',
    contentPackageId: 'package-1',
    question: 'A sufficiently detailed scenario question for taxonomy testing.',
    options: const <String>['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Explanation',
    reference: 'Reference',
    difficulty: 'Hard',
    tags: tags,
  );
}

void main() {
  group('Question hierarchy navigation tags', () {
    test('legacy placement IDs produce canonical hierarchy tags', () {
      expect(_question().navigationTags, const <String>[
        'd07_c02',
        'd07_c02_t01',
        'd07_c02_t01_s03',
      ]);
    });

    test('canonical placement IDs preserve exact hierarchy numbers', () {
      final question = _question(
        domain: 4,
        competencyId: 'd04_c06',
        topicId: 'd04_c06_t12',
        subtopicId: 'd04_c06_t12_s09',
      );

      expect(question.navigationTags, const <String>[
        'd04_c06',
        'd04_c06_t12',
        'd04_c06_t12_s09',
      ]);
    });

    test('topic can be derived from canonical subtopic ID', () {
      final question = _question(topicId: '', subtopicId: 'd07_c02_t05_s04');

      expect(question.navigationTags, const <String>[
        'd07_c02',
        'd07_c02_t05',
        'd07_c02_t05_s04',
      ]);
    });

    test('stale hierarchy tags are removed on import', () {
      final question = Question.fromJson(
        _question().toJson()
          ..['tags'] = const <String>[
            'd99_c99',
            'd07_c02_t88',
            'd07_c02_t88_s77',
            'risk control',
            'Risk Control',
            'permit to work',
          ],
      );

      expect(question.tags, const <String>['risk control', 'permit to work']);

      expect(question.allTags, const <String>[
        'd07_c02',
        'd07_c02_t01',
        'd07_c02_t01_s03',
        'risk control',
        'permit to work',
      ]);
    });

    test('serialization always persists canonical hierarchy tags', () {
      expect(_question().toJson()['tags'], const <String>[
        'd07_c02',
        'd07_c02_t01',
        'd07_c02_t01_s03',
        'risk control',
        'hierarchy of controls',
      ]);
    });

    test('automatic hierarchy tags remain separate from authored tags', () {
      final reloaded = Question.fromJson(_question().toJson());

      expect(reloaded.tags, const <String>[
        'risk control',
        'hierarchy of controls',
      ]);
      expect(reloaded.navigationTags, hasLength(3));
    });
  });
}
