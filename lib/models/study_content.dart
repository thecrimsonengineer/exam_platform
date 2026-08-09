import 'dart:convert';

/// Represents one CSP study competency.
///
/// Example:
/// Domain 7 -> Competency 1 -> Needs Assessment
class StudyContent {
  final String id;
  final String domainId;
  final String competencyId;
  final int competencyNumber;
  final String title;
  final String status;
  final int version;
  final List<StudySubtopic> subtopics;

  const StudyContent({
    required this.id,
    required this.domainId,
    required this.competencyId,
    required this.competencyNumber,
    required this.title,
    required this.status,
    required this.version,
    required this.subtopics,
  });

  factory StudyContent.fromJson(Map<String, dynamic> json) {
    return StudyContent(
      id: json['id']?.toString() ?? '',
      domainId: json['domainId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      competencyNumber: _toInt(json['competencyNumber']),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      version: _toInt(json['version'], defaultValue: 1),
      subtopics: _mapList(json['subtopics'])
          .map(StudySubtopic.fromJson)
          .toList(),
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
      'subtopics': subtopics.map((item) => item.toJson()).toList(),
    };
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  static List<dynamic> _toList(dynamic value) {
    return value is List ? value : <dynamic>[];
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

/// Represents one study subtopic within a CSP competency.
class StudySubtopic {
  final String id;
  final String title;
  final List<String> learningObjectives;
  final List<MainContentTopic> mainContent;
  final List<ContentEntry> keyPoints;
  final List<ContentEntry> examples;
  final List<ContentEntry> caseStudies;
  final List<ContentEntry> formulas;
  final List<ContentEntry> references;
  final List<ContentEntry> examTips;
  final List<ContentEntry> commonMistakes;
  final List<ContentEntry> keyTakeaways;

  /// Quizzes associated with the entire subtopic.
  final List<QuizReference> quizzes;

  const StudySubtopic({
    required this.id,
    required this.title,
    required this.learningObjectives,
    required this.mainContent,
    required this.keyPoints,
    required this.examples,
    required this.caseStudies,
    required this.formulas,
    required this.references,
    required this.examTips,
    required this.commonMistakes,
    required this.keyTakeaways,
    required this.quizzes,
  });

  factory StudySubtopic.fromJson(Map<String, dynamic> json) {
    return StudySubtopic(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      learningObjectives: _stringList(json['learningObjectives']),
      mainContent: _mapList(json['mainContent'])
          .map(MainContentTopic.fromJson)
          .toList(),
      keyPoints: _mapList(json['keyPoints'])
          .map(ContentEntry.fromJson)
          .toList(),
      examples: _mapList(json['examples'])
          .map(ContentEntry.fromJson)
          .toList(),
      caseStudies: _mapList(json['caseStudies'])
          .map(ContentEntry.fromJson)
          .toList(),
      formulas: _mapList(json['formulas'])
          .map(ContentEntry.fromJson)
          .toList(),
      references: _mapList(json['references'])
          .map(ContentEntry.fromJson)
          .toList(),
      examTips: _mapList(json['examTips'])
          .map(ContentEntry.fromJson)
          .toList(),
      commonMistakes: _mapList(json['commonMistakes'])
          .map(ContentEntry.fromJson)
          .toList(),
      keyTakeaways: _mapList(json['keyTakeaways'])
          .map(ContentEntry.fromJson)
          .toList(),
      quizzes: _mapList(json['quizzes'])
          .map(QuizReference.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'learningObjectives': learningObjectives,
      'mainContent': mainContent.map((item) => item.toJson()).toList(),
      'keyPoints': keyPoints.map((item) => item.toJson()).toList(),
      'examples': examples.map((item) => item.toJson()).toList(),
      'caseStudies': caseStudies.map((item) => item.toJson()).toList(),
      'formulas': formulas.map((item) => item.toJson()).toList(),
      'references': references.map((item) => item.toJson()).toList(),
      'examTips': examTips.map((item) => item.toJson()).toList(),
      'commonMistakes':
          commonMistakes.map((item) => item.toJson()).toList(),
      'keyTakeaways': keyTakeaways.map((item) => item.toJson()).toList(),
      'quizzes': quizzes.map((item) => item.toJson()).toList(),
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

/// Represents one topic inside the Main Content section.
///
/// A subtopic can have unlimited Main Content topics.
class MainContentTopic {
  final String id;
  final String title;
  final List<ContentBlock> blocks;

  /// Quizzes associated specifically with this main-content topic.
  final List<QuizReference> quizzes;

  const MainContentTopic({
    required this.id,
    required this.title,
    required this.blocks,
    required this.quizzes,
  });

  factory MainContentTopic.fromJson(Map<String, dynamic> json) {
    return MainContentTopic(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      blocks: _blockList(json['blocks']),
      quizzes: _quizReferenceList(json['quizzes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
    };
  }

  static List<ContentBlock> _blockList(dynamic value) {
    if (value is! List) {
      return <ContentBlock>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => ContentBlock.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static List<QuizReference> _quizReferenceList(dynamic value) {
    if (value is! List) {
      return <QuizReference>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => QuizReference.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((quiz) => quiz.quizId.isNotEmpty)
        .toList();
  }
}

/// Represents a reusable structured content block.
///
/// Examples:
/// heading
/// text
/// image
/// table
/// formula
/// warning
/// examTip
/// remember
/// quote
/// reference
/// quiz
/// caseStudy
/// checklist
class ContentBlock {
  final String id;
  final String type;
  final Map<String, dynamic> data;

  const ContentBlock({
    required this.id,
    required this.type,
    required this.data,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return ContentBlock(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
    };
  }

  String get content {
    return data['content']?.toString() ?? '';
  }

  String get text {
    return data['text']?.toString() ?? '';
  }

  String get title {
    return data['title']?.toString() ?? '';
  }

  int get level {
    final value = data['level'];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 2;
  }

  String? get image {
    final value = data['image'];

    if (value == null) {
      return null;
    }

    final path = value.toString().trim();

    if (path.isEmpty) {
      return null;
    }

    return path;
  }

  bool get hasImage {
    return image != null;
  }

  List<String> get columns {
    final value = data['columns'];

    if (value is! List) {
      return <String>[];
    }

    return value.map((item) => item.toString()).toList();
  }

  List<List<String>> get rows {
    final value = data['rows'];

    if (value is! List) {
      return <List<String>>[];
    }

    return value
        .whereType<List>()
        .map(
          (row) => row.map((cell) => cell.toString()).toList(),
        )
        .toList();
  }
}

/// Represents a reusable entry such as:
///
/// key point
/// example
/// case study
/// formula
/// reference
/// exam tip
/// common mistake
/// key takeaway
///
/// Complex entries can contain blocks.
class ContentEntry {
  final String id;
  final String title;
  final String content;
  final String source;
  final String url;
  final List<ContentBlock> blocks;

  const ContentEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.url,
    required this.blocks,
  });

  factory ContentEntry.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'];

    return ContentEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      blocks: rawBlocks is List
          ? rawBlocks
              .whereType<Map>()
              .map(
                (item) => ContentBlock.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <ContentBlock>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'source': source,
      'url': url,
      'blocks': blocks.map((block) => block.toJson()).toList(),
    };
  }
}

/// References an existing quiz from the legacy quiz system.
///
/// The study-content system stores only the quiz ID.
/// The actual questions remain owned by the legacy quiz system.
///
/// Example:
///
/// {
///   "quizId": "d07_01_tna_001"
/// }
class QuizReference {
  final String quizId;

  const QuizReference({
    required this.quizId,
  });

  factory QuizReference.fromJson(Map<String, dynamic> json) {
    return QuizReference(
      quizId: json['quizId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
    };
  }
}

/// Utility for decoding a JSON string directly into StudyContent.
StudyContent studyContentFromJson(String source) {
  final decoded = json.decode(source);

  if (decoded is! Map) {
    throw const FormatException(
      'Study content JSON must contain an object at the root.',
    );
  }

  return StudyContent.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

/// Utility for encoding StudyContent as a JSON string.
String studyContentToJson(StudyContent content) {
  return json.encode(content.toJson());
}