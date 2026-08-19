import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';
import 'cloud_question_repository.dart';
import 'local_question_repository.dart';
import 'question_quality_validator.dart';

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
  Future<List<QuestionQualityIssue>> saveDraft(Question question) async {
    final issues = validate(question);

    final cloud = _cloudRepository;
    if (cloud != null) {
      await cloud.save(question);
    }

    await _repository.save(question);

    return issues;
  }

  /// Publishes a question only when all mandatory quality checks pass.
  ///
  /// Publication is independent of the dedicated subtopic quiz minimum.
  /// A valid question may be published even when the subtopic has fewer
  /// than five published questions. The five-question rule controls quiz
  /// readiness/linking, not individual question publication.
  Future<void> publish(Question question) async {
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

    while (existing.contains(id)) {
      id += Random().nextInt(997) + 1;
    }

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
}
