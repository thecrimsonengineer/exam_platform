import 'dart:math';

import '../models/question.dart';
import 'local_question_repository.dart';
import 'question_quality_validator.dart';

class QuestionBankService {
  QuestionBankService({
    LocalQuestionRepository? repository,
    this.answerLengthCheckEnabled = true,
  }) : _repository = repository ?? LocalQuestionRepository.instance;

  final LocalQuestionRepository _repository;

  /// Controls only the answer-length quality criterion.
  ///
  /// ON by default.
  /// All other quality checks remain active when this is OFF.
  bool answerLengthCheckEnabled;

  QuestionQualityValidator get _validator => QuestionQualityValidator(
    answerLengthCheckEnabled: answerLengthCheckEnabled,
  );

  Future<void> initialize() => _repository.initialize();

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

    await _repository.save(question);

    return issues;
  }

  /// Publishes a question only when all mandatory quality checks pass.
  Future<void> publish(
    Question question, {
    required int quizQuestionCount,
  }) async {
    final issues = validate(question);

    if (quizQuestionCount < 5) {
      throw StateError(
        'A subtopic quiz must contain atleast 5 questions '
        'before publication.',
      );
    }

    if (issues.any((issue) => issue.isError)) {
      throw StateError(issues.map((issue) => issue.message).join('\n'));
    }

    final publishedQuestion = randomizeOptions(
      Question.fromJson({...question.toJson(), 'status': 'published'}),
    );

    await _repository.save(publishedQuestion);
  }

  Future<void> delete(int questionId) => _repository.delete(questionId);

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
