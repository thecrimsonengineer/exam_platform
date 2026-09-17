class Question {
  final int id;

  /// CSP domain number.
  final int domain;

  /// Official competency identifier.
  final String competencyId;

  /// Subtopic identifier.
  final String subtopicId;

  /// Main content topic identifier.
  /// Empty when the question covers the subtopic rather than one specific topic.
  final String topicId;

  /// Quiz to which this question belongs.
  final String quizId;

  /// Content package/version that produced the question.
  final String contentPackageId;

  /// Question stem.
  final String question;

  /// Exactly four answer options.
  final List<String> options;

  /// Zero-based index of the BEST/correct answer.
  final int correctAnswer;

  /// Explanation of the correct answer.
  final String explanation;

  /// Optional internal rationale for why the BEST answer is superior.
  ///
  /// This is retained for compatibility with the current application.
  /// It is not required during Complete Question Paste.
  final String bestAnswerRationale;

  /// Authoritative reference/source for the question.
  final String reference;

  /// Question difficulty.
  final String difficulty;

  /// Cognitive level.
  final String cognitiveLevel;

  /// Question type.
  final String questionType;

  /// Repository lifecycle status.
  final String status;

  /// Question version.
  final int version;

  /// Search and classification tags.
  final List<String> tags;

  const Question({
    required this.id,
    required this.domain,
    required this.competencyId,
    required this.subtopicId,
    required this.topicId,
    this.quizId = '',
    this.contentPackageId = '',
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.bestAnswerRationale = '',
    required this.reference,
    required this.difficulty,
    this.cognitiveLevel = 'application',
    this.questionType = 'scenario_mcq',
    this.status = 'draft',
    this.version = 1,
    required this.tags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: _toInt(json['id']),
      domain: _toInt(json['domain']),
      competencyId: json['competencyId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      contentPackageId: json['contentPackageId']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: _stringList(json['options']),
      correctAnswer: _toInt(json['correctAnswer']),
      explanation: json['explanation']?.toString() ?? '',
      bestAnswerRationale: json['bestAnswerRationale']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'Hard',
      cognitiveLevel: json['cognitiveLevel']?.toString() ?? 'application',
      questionType: json['questionType']?.toString() ?? 'scenario_mcq',
      status: json['status']?.toString() ?? 'draft',
      version: _toInt(json['version'], defaultValue: 1),
      tags: _authoredTags(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'competencyId': competencyId,
      'subtopicId': subtopicId,
      'topicId': topicId,
      'quizId': quizId,
      'contentPackageId': contentPackageId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'bestAnswerRationale': bestAnswerRationale,
      'reference': reference,
      'difficulty': difficulty,
      'cognitiveLevel': cognitiveLevel,
      'questionType': questionType,
      'status': status,
      'version': version,
      'tags': allTags,
    };
  }

  static final RegExp _hierarchyTagPattern = RegExp(
    r'^d\d{2}_c\d{2}(?:_t\d{2})?(?:_s\d{2})?$',
    caseSensitive: false,
  );

  /// Canonical learner-navigation tags derived from structured placement.
  ///
  /// The displayed tag format is intentionally independent of older stored
  /// topic/subtopic ID shapes so legacy questions can still expose the new
  /// learner hierarchy without rewriting their placement IDs.
  List<String> get navigationTags {
    final competencyNumber = _competencyNumberFrom(competencyId);

    if (domain <= 0 || competencyNumber == null) {
      return const <String>[];
    }

    final domainPart = domain.toString().padLeft(2, '0');
    final competencyPart = competencyNumber.toString().padLeft(2, '0');
    final competencyTag = 'd${domainPart}_c$competencyPart';

    final values = <String>[competencyTag];
    final topicNumber = _topicNumberFrom(topicId, subtopicId);

    if (topicNumber == null) {
      return List<String>.unmodifiable(values);
    }

    final topicTag =
        '${competencyTag}_t${topicNumber.toString().padLeft(2, '0')}';
    values.add(topicTag);

    final subtopicNumber = _subtopicNumberFrom(subtopicId);

    if (subtopicNumber != null) {
      values.add('${topicTag}_s${subtopicNumber.toString().padLeft(2, '0')}');
    }

    return List<String>.unmodifiable(values);
  }

  /// Navigation tags first, followed by meaningful authored/search tags.
  ///
  /// Any stale hierarchy-shaped tags supplied by older imports are discarded
  /// and regenerated from the structured question placement.
  List<String> get allTags {
    final values = <String>[];
    final seen = <String>{};

    for (final tag in navigationTags) {
      if (seen.add(tag.toLowerCase())) {
        values.add(tag);
      }
    }

    for (final rawTag in tags) {
      final tag = rawTag.trim();

      if (tag.isEmpty || _hierarchyTagPattern.hasMatch(tag)) {
        continue;
      }

      if (seen.add(tag.toLowerCase())) {
        values.add(tag);
      }
    }

    return List<String>.unmodifiable(values);
  }

  static int? _competencyNumberFrom(String value) {
    final match = RegExp(
      r'(?:^|_)c(\d+)(?:_|$)',
      caseSensitive: false,
    ).firstMatch(value.trim());

    return int.tryParse(match?.group(1) ?? '');
  }

  static int? _topicNumberFrom(String topicValue, String subtopicValue) {
    final pattern = RegExp(r'(?:^|_)t(\d+)(?:_|$)', caseSensitive: false);

    for (final value in <String>[topicValue, subtopicValue]) {
      final match = pattern.firstMatch(value.trim());
      final number = int.tryParse(match?.group(1) ?? '');

      if (number != null) {
        return number;
      }
    }

    return null;
  }

  static int? _subtopicNumberFrom(String value) {
    final normalized = value.trim();

    final canonical = RegExp(
      r'(?:^|_)s(\d+)(?:_|$)',
      caseSensitive: false,
    ).firstMatch(normalized);

    final canonicalNumber = int.tryParse(canonical?.group(1) ?? '');

    if (canonicalNumber != null) {
      return canonicalNumber;
    }

    // Legacy CSP11 subtopic IDs commonly ended in "_01", "_02", etc.
    // Keep those records navigable while displaying the new canonical tags.
    final legacy = RegExp(r'_(\d+)$').firstMatch(normalized);
    return int.tryParse(legacy?.group(1) ?? '');
  }

  static List<String> _authoredTags(dynamic value) {
    final values = <String>[];
    final seen = <String>{};

    for (final rawTag in _stringList(value)) {
      final tag = rawTag.trim();

      if (tag.isEmpty || _hierarchyTagPattern.hasMatch(tag)) {
        continue;
      }

      if (seen.add(tag.toLowerCase())) {
        values.add(tag);
      }
    }

    return values;
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item?.toString() ?? '')
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}
