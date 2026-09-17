import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/bookmark_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Question _question({
  int id = 101,
  String stem = 'A worker is exposed to a hazard. Which control is best?',
}) {
  return Question(
    id: id,
    domain: 3,
    competencyId: 'd03_c02',
    topicId: 'd03_c02_t01',
    subtopicId: 'd03_c02_t01_s01',
    quizId: 'd03_c02_t01_s01_quiz',
    contentPackageId: 'd03_c02-v1',
    question: stem,
    options: const <String>[
      'Eliminate the hazard',
      'Issue a warning',
      'Provide training',
      'Post a sign',
    ],
    correctAnswer: 0,
    explanation: 'Elimination removes the hazard at source.',
    reference: 'Hierarchy of controls',
    difficulty: 'Hard',
    cognitiveLevel: 'Application',
    questionType: 'scenario_mcq',
    status: 'published',
    version: 1,
    tags: const <String>['risk', 'controls'],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('BookmarkService local question cache', () {
    test(
      'toggleQuestion stores the ID and complete recallable snapshot',
      () async {
        final service = BookmarkService();
        final question = _question();

        await service.toggleQuestion(question);

        final ids = await service.getBookmarkedQuestionIds();
        final questions = await service.getBookmarkedQuestions();

        expect(ids, contains(question.id));
        expect(questions, hasLength(1));
        expect(questions.single.id, question.id);
        expect(questions.single.question, question.question);
        expect(questions.single.options, question.options);
        expect(questions.single.explanation, question.explanation);
        expect(questions.single.reference, question.reference);
        expect(questions.single.navigationTags, question.navigationTags);
      },
    );

    test(
      'bookmark snapshot persists across BookmarkService instances',
      () async {
        final question = _question(id: 202);

        await BookmarkService().addQuestion(question);

        final reloaded = await BookmarkService().getBookmarkedQuestions();

        expect(reloaded, hasLength(1));
        expect(reloaded.single.id, 202);
        expect(reloaded.single.question, question.question);
      },
    );

    test('newest bookmarked question is returned first', () async {
      final service = BookmarkService();

      await service.addQuestion(_question(id: 1, stem: 'First saved question'));
      await service.addQuestion(
        _question(id: 2, stem: 'Second saved question'),
      );

      final questions = await service.getBookmarkedQuestions();

      expect(questions.map((item) => item.id).toList(), <int>[2, 1]);
    });

    test('toggleQuestion removes both ID and snapshot', () async {
      final service = BookmarkService();
      final question = _question();

      await service.toggleQuestion(question);
      await service.toggleQuestion(question);

      expect(await service.isBookmarked(question.id), isFalse);
      expect(await service.getBookmarkedQuestions(), isEmpty);
    });

    test('removeBookmark removes a cached question snapshot too', () async {
      final service = BookmarkService();
      final question = _question();

      await service.addQuestion(question);
      await service.removeBookmark(question.id);

      expect(
        await service.getBookmarkedQuestionIds(),
        isNot(contains(question.id)),
      );
      expect(await service.getBookmarkedQuestions(), isEmpty);
    });

    test(
      'legacy ID-only bookmark remains recognized without inventing content',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'bookmarked_question_ids': <String>['707'],
        });

        final service = BookmarkService();

        expect(await service.isBookmarked(707), isTrue);
        expect(await service.getBookmarkCount(), 1);
        expect(await service.getBookmarkedQuestions(), isEmpty);
      },
    );

    test(
      'one malformed snapshot does not block valid cached bookmarks',
      () async {
        final question = _question(id: 808);
        final service = BookmarkService();

        await service.addQuestion(question);

        final prefs = await SharedPreferences.getInstance();
        final current =
            prefs.getStringList('bookmarked_question_snapshots_v2') ??
            <String>[];
        await prefs.setStringList('bookmarked_question_snapshots_v2', <String>[
          'not-json',
          ...current,
        ]);

        final questions = await service.getBookmarkedQuestions();

        expect(questions, hasLength(1));
        expect(questions.single.id, 808);
      },
    );

    test(
      'clearAllBookmarks removes IDs and cached question snapshots',
      () async {
        final service = BookmarkService();

        await service.addQuestion(_question(id: 1));
        await service.addQuestion(_question(id: 2));
        await service.clearAllBookmarks();

        expect(await service.getBookmarkedQuestionIds(), isEmpty);
        expect(await service.getBookmarkedQuestions(), isEmpty);
        expect(await service.getBookmarkCount(), 0);
      },
    );
  });
}
