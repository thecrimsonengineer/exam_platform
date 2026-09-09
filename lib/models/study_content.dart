import 'package:equatable/equatable.dart';

import 'question.dart';

/// CSP11 learning content root.
///
/// Frozen hierarchy:
///
/// Domain
///   -> Competency
///       -> Content Package
///           -> Content Version
///               -> Topic
///                   -> Subtopic
///                       -> Content Blocks
///                           -> Practice Questions
///
/// StudyContent represents the content version consumed by the
/// application. Topic and Subtopic are learning-navigation units.
class StudyContent extends Equatable {
  final String id;
  final String domainId;
  final String competencyId;
  final int competencyNumber;
  final String title;
  final String status;
  final int version;
  final List<StudyTopic> topics;

  const StudyContent({
    required this.id,
    required this.domainId,
    required this.competencyId,
    required this.competencyNumber,
    required this.title,
    required this.status,
    required this.version,
    this.topics = const [],
  });

  factory StudyContent.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'];

    return StudyContent(
      id: json['id']?.toString() ?? '',
      domainId: json['domainId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      competencyNumber: _toInt(json['competencyNumber']),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Draft',
      version: _toInt(json['version'], fallback: 1),
      topics: rawTopics is List
          ? rawTopics
                .whereType<Map>()
                .map(
                  (item) =>
                      StudyTopic.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domainId': domainId,
      'competencyId': competencyId,
      'competencyNumber': competencyNumber,
      'title': title,
      'status': status,
      'version': version,
      'topics': topics.map((topic) => topic.toJson()).toList(),
    };
  }

  StudyContent copyWith({
    String? id,
    String? domainId,
    String? competencyId,
    int? competencyNumber,
    String? title,
    String? status,
    int? version,
    List<StudyTopic>? topics,
  }) {
    return StudyContent(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      competencyId: competencyId ?? this.competencyId,
      competencyNumber: competencyNumber ?? this.competencyNumber,
      title: title ?? this.title,
      status: status ?? this.status,
      version: version ?? this.version,
      topics: topics ?? this.topics,
    );
  }

  @override
  List<Object?> get props => [
    id,
    domainId,
    competencyId,
    competencyNumber,
    title,
    status,
    version,
    topics,
  ];
}

/// Topic is the first learner-facing learning-navigation level.
///
/// Frozen hierarchy:
///
/// StudyContent
///   -> StudyTopic
///       -> StudySubtopic
///           -> ContentBlock
class StudyTopic extends Equatable {
  final String id;
  final String title;
  final List<StudySubtopic> subtopics;

  const StudyTopic({
    required this.id,
    required this.title,
    this.subtopics = const [],
  });

  factory StudyTopic.fromJson(Map<String, dynamic> json) {
    final rawSubtopics = json['subtopics'];

    return StudyTopic(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtopics: rawSubtopics is List
          ? rawSubtopics
                .whereType<Map>()
                .map(
                  (item) =>
                      StudySubtopic.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtopics': subtopics.map((subtopic) => subtopic.toJson()).toList(),
    };
  }

  StudyTopic copyWith({
    String? id,
    String? title,
    List<StudySubtopic>? subtopics,
  }) {
    return StudyTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      subtopics: subtopics ?? this.subtopics,
    );
  }

  @override
  List<Object?> get props => [id, title, subtopics];
}

/// Subtopic is the second learner-facing learning-navigation level.
///
/// A Subtopic contains ContentBlocks directly.
///
/// There is intentionally NO intermediate MainContent layer.
class StudySubtopic extends Equatable {
  final String id;
  final String title;
  final List<ContentBlock> blocks;
  final List<dynamic> questions;
  final List<String> learningObjectives;
  final List<String> keyPoints;
  final List<String> examples;
  final List<String> caseStudies;
  final List<String> formulas;
  final List<String> references;
  final List<String> examTips;
  final List<String> commonMistakes;
  final List<String> keyTakeaways;
  final List<QuizReference> quizzes;

  const StudySubtopic({
    required this.id,
    required this.title,
    this.blocks = const [],
    this.questions = const [],
    this.learningObjectives = const [],
    this.keyPoints = const [],
    this.examples = const [],
    this.caseStudies = const [],
    this.formulas = const [],
    this.references = const [],
    this.examTips = const [],
    this.commonMistakes = const [],
    this.keyTakeaways = const [],
    this.quizzes = const [],
  });

  factory StudySubtopic.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'];

    return StudySubtopic(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      blocks: rawBlocks is List
          ? rawBlocks
                .whereType<Map>()
                .map(
                  (item) =>
                      ContentBlock.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      questions: json['questions'] is List
          ? (json['questions'] as List).map((item) {
              if (item is Question) {
                return item;
              }

              if (item is Map) {
                return Question.fromJson(Map<String, dynamic>.from(item));
              }

              return item;
            }).toList()
          : const [],
      learningObjectives: _toStringList(json['learningObjectives']),
      keyPoints: _toStringList(json['keyPoints']),
      examples: _toStringList(json['examples']),
      caseStudies: _toStringList(json['caseStudies']),
      formulas: _toStringList(json['formulas']),
      references: _toStringList(json['references']),
      examTips: _toStringList(json['examTips']),
      commonMistakes: _toStringList(json['commonMistakes']),
      keyTakeaways: _toStringList(json['keyTakeaways']),
      quizzes: json['quizzes'] is List
          ? (json['quizzes'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      QuizReference.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'questions': questions
          .map(
            (question) => question is Question ? question.toJson() : question,
          )
          .toList(),
      'learningObjectives': learningObjectives,
      'keyPoints': keyPoints,
      'examples': examples,
      'caseStudies': caseStudies,
      'formulas': formulas,
      'references': references,
      'examTips': examTips,
      'commonMistakes': commonMistakes,
      'keyTakeaways': keyTakeaways,
      'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
    };
  }

  StudySubtopic copyWith({
    String? id,
    String? title,
    List<ContentBlock>? blocks,
    List<dynamic>? questions,
    List<String>? learningObjectives,
    List<String>? keyPoints,
    List<String>? examples,
    List<String>? caseStudies,
    List<String>? formulas,
    List<String>? references,
    List<String>? examTips,
    List<String>? commonMistakes,
    List<String>? keyTakeaways,
    List<QuizReference>? quizzes,
  }) {
    return StudySubtopic(
      id: id ?? this.id,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      questions: questions ?? this.questions,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      keyPoints: keyPoints ?? this.keyPoints,
      examples: examples ?? this.examples,
      caseStudies: caseStudies ?? this.caseStudies,
      formulas: formulas ?? this.formulas,
      references: references ?? this.references,
      examTips: examTips ?? this.examTips,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      quizzes: quizzes ?? this.quizzes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    blocks,
    questions,
    learningObjectives,
    keyPoints,
    examples,
    caseStudies,
    formulas,
    references,
    examTips,
    commonMistakes,
    keyTakeaways,
    quizzes,
  ];
}

/// Generic CSP11 learning-content block.
///
/// Block types remain flexible and are intentionally not changed by
/// the Topic/Subtopic architecture replacement.
class ContentBlock extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> data;

  const ContentBlock({
    required this.id,
    required this.type,
    this.data = const {},
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'data': data};
  }

  ContentBlock copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
  }) {
    return ContentBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [id, type, data];
}

/// Retained for the existing quiz/content architecture.
class QuizReference extends Equatable {
  final String quizId;

  const QuizReference({required this.quizId});

  factory QuizReference.fromJson(Map<String, dynamic> json) {
    return QuizReference(quizId: json['quizId']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'quizId': quizId};
  }

  @override
  List<Object?> get props => [quizId];
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _toStringList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}
