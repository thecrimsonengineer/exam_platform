import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';
import 'cloud_question_repository.dart';
import 'local_question_repository.dart';
import 'question_quality_validator.dart';

class QuestionDraftBatchResult {
  final int addedCount;
  final int duplicateCount;
  final List<Question> savedQuestions;

  const QuestionDraftBatchResult({
    required this.addedCount,
    required this.duplicateCount,
    required this.savedQuestions,
  });

  int get processedCount => addedCount + duplicateCount;
}

class _QuestionDraftSaveOutcome {
  final Question question;
  final List<QuestionQualityIssue> issues;
  final bool duplicate;

  const _QuestionDraftSaveOutcome({
    required this.question,
    required this.issues,
    required this.duplicate,
  });
}

/// Central managed-question service for CSP11.
///
/// Admin authoring is Firebase-backed when the default repository is used.
/// LocalQuestionRepository remains available for local cache and migration
/// workflows. Student question loading is handled by QuizService through
/// CloudQuestionRepository.
class QuestionBankService {
  QuestionBankService({
    LocalQuestionRepository? repository,
    CloudQuestionRepository? cloudRepository,
    this.answerLengthCheckEnabled = true,
  }) : _repository = repository ?? LocalQuestionRepository.instance,
       _cloudRepository = repository == null
           ? (cloudRepository ?? CloudQuestionRepository())
           : cloudRepository;

  final LocalQuestionRepository _repository;
  final CloudQuestionRepository? _cloudRepository;
  int _lastIssuedQuestionId = 0;

  static const String _cloudSeededKey = 'csp11.question_bank.cloud_seeded.v1';

  /// Controls only the answer-length quality criterion.
  ///
  /// ON by default.
  /// All other quality checks remain active when this is OFF.
  bool answerLengthCheckEnabled;

  QuestionQualityValidator get _validator => QuestionQualityValidator(
    answerLengthCheckEnabled: answerLengthCheckEnabled,
  );

  Future<void> initialize() async {
    await _repository.initialize();

    final cloud = _cloudRepository;
    if (cloud == null) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final cloudSeeded = preferences.getBool(_cloudSeededKey) ?? false;
    final cloudQuestions = await cloud.loadAll();

    if (cloudQuestions.isNotEmpty) {
      await _repository.replaceAll(cloudQuestions);
      await preferences.setBool(_cloudSeededKey, true);
      return;
    }

    if (!cloudSeeded && _repository.questions.isNotEmpty) {
      for (final question in _repository.questions) {
        await cloud.save(question);
      }

      await preferences.setBool(_cloudSeededKey, true);
      return;
    }

    if (cloudSeeded) {
      await _repository.replaceAll(const <Question>[]);
    }
  }

  List<Question> allManagedQuestions() => _repository.questions;

  List<Question> byQuizId(String quizId) => _repository.byQuizId(quizId);

  /// Runs the complete CSP11 question quality gate.
  List<QuestionQualityIssue> validate(Question question) {
    return _validator.validate(question);
  }

  /// Saves a question as DRAFT.
  ///
  /// Validation issues are returned to the caller, but do not prevent
  /// saving the draft. This allows incomplete questions to remain editable.
  ///
  /// The persisted lifecycle status is always normalized to DRAFT.
  Future<List<QuestionQualityIssue>> saveDraft(Question question) async {
    final outcome = await _saveDraftInternal(question);
    return outcome.issues;
  }

  /// Saves a batch of draft questions only after duplicate/context preflight.
  ///
  /// Exact re-imports in the same Studio placement are skipped without
  /// creating a second numeric ID. A same-stem conflict with changed content
  /// or a different competency/subtopic/topic is rejected before any item in
  /// the batch is written.
  Future<QuestionDraftBatchResult> saveDraftBatch(
    List<Question> questions,
  ) async {
    if (questions.isEmpty) {
      return const QuestionDraftBatchResult(
        addedCount: 0,
        duplicateCount: 0,
        savedQuestions: <Question>[],
      );
    }

    await _repository.initialize();
    _preflightDraftBatch(questions);

    var addedCount = 0;
    var duplicateCount = 0;
    final savedQuestions = <Question>[];

    for (final question in questions) {
      final outcome = await _saveDraftInternal(question);
      savedQuestions.add(outcome.question);

      if (outcome.duplicate) {
        duplicateCount++;
      } else {
        addedCount++;
      }
    }

    return QuestionDraftBatchResult(
      addedCount: addedCount,
      duplicateCount: duplicateCount,
      savedQuestions: List<Question>.unmodifiable(savedQuestions),
    );
  }

  Future<_QuestionDraftSaveOutcome> _saveDraftInternal(
    Question question,
  ) async {
    await _repository.initialize();

    final issues = validate(question);
    final matches = _repository.questions
        .where((existing) => _sameQuestionIdentity(existing, question))
        .toList();

    if (matches.length > 1) {
      throw StateError(
        'Question identity conflict: multiple managed questions already use '
        'the same normalized question stem.',
      );
    }

    if (matches.isNotEmpty) {
      final existing = matches.single;

      if (!_samePlacement(existing, question)) {
        throw StateError(
          'Duplicate question already exists under '
          '${existing.competencyId} / ${existing.subtopicId} / '
          '${existing.topicId}. It was not added to '
          '${question.competencyId} / ${question.subtopicId} / '
          '${question.topicId}.',
        );
      }

      if (!_equivalentQuestionContent(existing, question)) {
        throw StateError(
          'A question with the same stem already exists as ID '
          '${existing.id}, but its answers or metadata differ. '
          'Edit the existing managed question instead of importing a new ID.',
        );
      }

      return _QuestionDraftSaveOutcome(
        question: existing,
        issues: issues,
        duplicate: true,
      );
    }

    final draftQuestion = Question.fromJson({
      ...question.toJson(),
      'status': 'draft',
    });

    final cloud = _cloudRepository;
    if (cloud != null) {
      await cloud.save(draftQuestion);
    }

    await _repository.save(draftQuestion);

    return _QuestionDraftSaveOutcome(
      question: draftQuestion,
      issues: issues,
      duplicate: false,
    );
  }

  void _preflightDraftBatch(List<Question> questions) {
    final ids = <int>{};
    final identities = <String>{};

    for (final question in questions) {
      if (!ids.add(question.id)) {
        throw StateError(
          'Question import batch contains duplicate numeric ID ${question.id}.',
        );
      }

      final identity = _normalizedQuestionStem(question.question);
      if (identity.isEmpty) {
        continue;
      }

      if (!identities.add(identity)) {
        throw StateError(
          'Question import batch contains the same question stem more than '
          'once. Remove the duplicate before importing.',
        );
      }

      final matches = _repository.questions
          .where((existing) => _sameQuestionIdentity(existing, question))
          .toList();

      if (matches.length > 1) {
        throw StateError(
          'Question identity conflict: multiple managed questions already use '
          'the same normalized question stem.',
        );
      }

      if (matches.isEmpty) {
        continue;
      }

      final existing = matches.single;

      if (!_samePlacement(existing, question)) {
        throw StateError(
          'Duplicate question already exists under '
          '${existing.competencyId} / ${existing.subtopicId} / '
          '${existing.topicId}. Import was stopped before saving.',
        );
      }

      if (!_equivalentQuestionContent(existing, question)) {
        throw StateError(
          'Question ID ${existing.id} already uses the same stem but has '
          'different answers or metadata. Import was stopped before saving.',
        );
      }
    }
  }

  bool _sameQuestionIdentity(Question a, Question b) {
    final left = _normalizedQuestionStem(a.question);
    final right = _normalizedQuestionStem(b.question);
    return left.isNotEmpty && left == right;
  }

  bool _samePlacement(Question a, Question b) {
    return a.competencyId.trim() == b.competencyId.trim() &&
        a.subtopicId.trim() == b.subtopicId.trim() &&
        a.topicId.trim() == b.topicId.trim();
  }

  bool _equivalentQuestionContent(Question a, Question b) {
    final aCorrect = _normalizedCorrectAnswerText(a);
    final bCorrect = _normalizedCorrectAnswerText(b);

    final aOptions = a.options.map(_normalizedText).toList()..sort();
    final bOptions = b.options.map(_normalizedText).toList()..sort();

    final aTags = a.tags.map(_normalizedText).toList()..sort();
    final bTags = b.tags.map(_normalizedText).toList()..sort();

    return _sameStringList(aOptions, bOptions) &&
        aCorrect == bCorrect &&
        _normalizedText(a.explanation) == _normalizedText(b.explanation) &&
        _normalizedText(a.reference) == _normalizedText(b.reference) &&
        _normalizedText(a.bestAnswerRationale) ==
            _normalizedText(b.bestAnswerRationale) &&
        _normalizedText(a.difficulty) == _normalizedText(b.difficulty) &&
        _normalizedText(a.cognitiveLevel) ==
            _normalizedText(b.cognitiveLevel) &&
        _normalizedText(a.questionType) == _normalizedText(b.questionType) &&
        _sameStringList(aTags, bTags);
  }

  String _normalizedCorrectAnswerText(Question question) {
    if (question.correctAnswer < 0 ||
        question.correctAnswer >= question.options.length) {
      return '';
    }

    return _normalizedText(question.options[question.correctAnswer]);
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }

    return true;
  }

  String _normalizedQuestionStem(String value) {
    return _normalizedText(value)
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizedText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Publishes a preflighted bulk package while preserving managed-question
  /// identity.
  ///
  /// Existing exact duplicates retain their numeric IDs. Their derived quiz
  /// and content-package metadata may be rebound to the current competency
  /// revision without creating a second question record.
  ///
  /// Every incoming question is validated before any writes begin.
  Future<QuestionPreparedBatchPublishResult> publishPreparedBatch(
    List<Question> questions,
  ) async {
    if (questions.isEmpty) {
      return const QuestionPreparedBatchPublishResult(
        publishedQuestionCount: 0,
        reusedQuestionCount: 0,
      );
    }

    await _repository.initialize();

    final incomingIds = <int>{};
    final incomingIdentities = <String>{};
    final prepared = <_PreparedBulkQuestion>[];

    for (final question in questions) {
      if (!incomingIds.add(question.id)) {
        throw StateError(
          'Bulk publish contains duplicate numeric ID ${question.id}.',
        );
      }

      final identity = _normalizedQuestionStem(question.question);
      if (identity.isEmpty) {
        throw StateError('Bulk publish contains an empty question identity.');
      }

      if (!incomingIdentities.add(identity)) {
        throw StateError(
          'Bulk publish contains the same normalized question stem more '
          'than once.',
        );
      }

      final issues = validate(question);
      final errors = issues.where((issue) => issue.isError).toList();
      if (errors.isNotEmpty) {
        throw StateError(errors.map((issue) => issue.message).join('\n'));
      }

      final matches = _repository.questions
          .where((existing) => _sameQuestionIdentity(existing, question))
          .toList();

      if (matches.length > 1) {
        throw StateError(
          'Question identity conflict: multiple managed questions already '
          'use the same normalized question stem.',
        );
      }

      if (matches.isEmpty) {
        prepared.add(
          _PreparedBulkQuestion(
            question: question,
            existingStatus: null,
            reused: false,
          ),
        );
        continue;
      }

      final existing = matches.single;

      if (!_samePlacement(existing, question)) {
        throw StateError(
          'Duplicate question already exists under '
          '${existing.competencyId} / ${existing.subtopicId} / '
          '${existing.topicId}. Bulk publish was stopped before writing.',
        );
      }

      if (!_equivalentQuestionContent(existing, question)) {
        throw StateError(
          'Question ID ${existing.id} uses the same stem but different '
          'answers or metadata. Edit the existing question instead.',
        );
      }

      prepared.add(
        _PreparedBulkQuestion(
          question: Question.fromJson({
            ...question.toJson(),
            'id': existing.id,
          }),
          existingStatus: existing.status,
          reused: true,
        ),
      );
    }

    var reusedQuestionCount = 0;

    for (final item in prepared) {
      if (item.reused) {
        reusedQuestionCount++;
      }

      await _publishPreparedQuestion(
        item.question,
        existingStatus: item.existingStatus,
      );
    }

    return QuestionPreparedBatchPublishResult(
      publishedQuestionCount: prepared.length,
      reusedQuestionCount: reusedQuestionCount,
    );
  }

  Future<void> _publishPreparedQuestion(
    Question question, {
    required String? existingStatus,
  }) async {
    final normalizedStatus = existingStatus?.trim().toLowerCase() ?? '';

    Future<void> persistWithStatus(String status) async {
      final value = Question.fromJson({...question.toJson(), 'status': status});

      await _persistManagedQuestion(value);
    }

    if (normalizedStatus == 'published') {
      final published = randomizeOptions(
        Question.fromJson({...question.toJson(), 'status': 'published'}),
      );
      await _persistManagedQuestion(published);
      return;
    }

    if (normalizedStatus.isEmpty || normalizedStatus == 'draft') {
      await persistWithStatus('draft');
      await persistWithStatus('review');
      await persistWithStatus('validated');
    } else if (normalizedStatus == 'review') {
      await persistWithStatus('review');
      await persistWithStatus('validated');
    } else if (normalizedStatus == 'validated') {
      await persistWithStatus('validated');
    } else {
      throw StateError(
        'Unsupported existing question lifecycle status '
        '"$existingStatus" during bulk publish.',
      );
    }

    final published = randomizeOptions(
      Question.fromJson({...question.toJson(), 'status': 'published'}),
    );
    await _persistManagedQuestion(published);
  }

  Future<void> _persistManagedQuestion(Question question) async {
    final cloud = _cloudRepository;
    if (cloud != null) {
      await cloud.save(question);
    }

    await _repository.save(question);
  }

  /// Sends a question from DRAFT to REVIEW.
  ///
  /// No quality validation is performed here because incomplete questions
  /// are allowed to remain editable until the review stage.
  Future<void> sendToReview(Question question) async {
    if (_normalizedStatus(question) != 'draft') {
      throw StateError(
        'Question can only be sent to review from draft status.',
      );
    }

    final reviewQuestion = Question.fromJson({
      ...question.toJson(),
      'status': 'review',
    });

    final cloud = _cloudRepository;
    if (cloud != null) {
      await cloud.save(reviewQuestion);
    }

    await _repository.save(reviewQuestion);
  }

  /// Validates a question for publication.
  ///
  /// The question must already be in REVIEW status.
  ///
  /// The existing H0.3 quality validator is used without modification.
  ///
  /// Warning-only questions are allowed to become VALIDATED.
  /// Questions containing quality errors remain in REVIEW and are rejected.
  Future<List<QuestionQualityIssue>> validateForPublication(
    Question question,
  ) async {
    if (_normalizedStatus(question) != 'review') {
      throw StateError('Question can only be validated from review status.');
    }

    final issues = validate(question);

    if (issues.any((issue) => issue.isError)) {
      throw StateError(issues.map((issue) => issue.message).join('\n'));
    }

    final validatedQuestion = Question.fromJson({
      ...question.toJson(),
      'status': 'validated',
    });

    final cloud = _cloudRepository;
    if (cloud != null) {
      await cloud.save(validatedQuestion);
    }

    await _repository.save(validatedQuestion);

    return issues;
  }

  /// Publishes a question only when it has passed the lifecycle and quality
  /// gates.
  ///
  /// Publication is independent of the dedicated subtopic quiz minimum.
  /// A valid question may be published even when the subtopic has fewer
  /// than five published questions. The five-question rule controls quiz
  /// readiness/linking, not individual question publication.
  Future<void> publish(Question question) async {
    if (_normalizedStatus(question) != 'validated') {
      throw StateError('Question must be validated before publication.');
    }

    final issues = validate(question);

    if (issues.any((issue) => issue.isError)) {
      throw StateError(issues.map((issue) => issue.message).join('\n'));
    }

    final publishedQuestion = randomizeOptions(
      Question.fromJson({...question.toJson(), 'status': 'published'}),
    );

    final cloud = _cloudRepository;
    if (cloud != null) {
      await cloud.save(publishedQuestion);
    }

    await _repository.save(publishedQuestion);
  }

  Future<void> delete(int questionId) async {
    final cloud = _cloudRepository;
    if (cloud != null) {
      await cloud.delete(questionId);
    }

    await _repository.delete(questionId);
  }

  int nextQuestionId() {
    final existing = <int>{for (final q in _repository.questions) q.id};

    var id = DateTime.now().millisecondsSinceEpoch;

    if (id <= _lastIssuedQuestionId) {
      id = _lastIssuedQuestionId + 1;
    }

    while (existing.contains(id)) {
      id++;
    }

    _lastIssuedQuestionId = id;
    return id;
  }

  /// Randomizes answer positions while preserving
  /// the correct answer's relationship to its option.
  Question randomizeOptions(Question question) {
    final indexed = List.generate(
      question.options.length,
      (index) => MapEntry(index, question.options[index]),
    )..shuffle();

    final newOptions = indexed.map((entry) => entry.value).toList();

    final correct = indexed.indexWhere(
      (entry) => entry.key == question.correctAnswer,
    );

    return Question(
      id: question.id,
      domain: question.domain,
      competencyId: question.competencyId,
      subtopicId: question.subtopicId,
      topicId: question.topicId,
      quizId: question.quizId,
      contentPackageId: question.contentPackageId,
      question: question.question,
      options: newOptions,
      correctAnswer: correct,
      explanation: question.explanation,
      bestAnswerRationale: question.bestAnswerRationale,
      reference: question.reference,
      difficulty: question.difficulty,
      cognitiveLevel: question.cognitiveLevel,
      questionType: question.questionType,
      status: question.status,
      version: question.version,
      tags: question.tags,
    );
  }

  String _normalizedStatus(Question question) {
    return question.status.trim().toLowerCase();
  }
}

class QuestionPreparedBatchPublishResult {
  final int publishedQuestionCount;
  final int reusedQuestionCount;

  const QuestionPreparedBatchPublishResult({
    required this.publishedQuestionCount,
    required this.reusedQuestionCount,
  });
}

class _PreparedBulkQuestion {
  final Question question;
  final String? existingStatus;
  final bool reused;

  const _PreparedBulkQuestion({
    required this.question,
    required this.existingStatus,
    required this.reused,
  });
}
