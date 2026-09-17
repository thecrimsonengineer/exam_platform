import '../data/csp11_blueprint.dart';
import '../models/study_content.dart';
import 'study_content_loader.dart';

typedef StudyContentSearchLoader = Future<List<StudyContent>> Function();

class StudyContentSearchResult {
  final String domainId;
  final String domainLabel;
  final String domainTitle;
  final String competencyId;
  final String competencyTitle;
  final String topicId;
  final String topicTitle;
  final String subtopicId;
  final String subtopicTitle;
  final String matchSection;
  final String snippet;
  final int score;

  const StudyContentSearchResult({
    required this.domainId,
    required this.domainLabel,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    required this.topicId,
    required this.topicTitle,
    required this.subtopicId,
    required this.subtopicTitle,
    required this.matchSection,
    required this.snippet,
    required this.score,
  });

  String get breadcrumb =>
      '$domainLabel • ${competencyId.toUpperCase()} • $topicTitle';
}

class StudyContentSearchService {
  StudyContentSearchService({StudyContentSearchLoader? loadPublishedContent})
    : _loadPublishedContent =
          loadPublishedContent ?? _defaultLoadPublishedContent;

  final StudyContentSearchLoader _loadPublishedContent;
  Future<List<_StudyContentSearchEntry>>? _indexFuture;

  static Future<List<StudyContent>> _defaultLoadPublishedContent() {
    return const StudyContentLoader().loadPublishedContent();
  }

  /// Search is lazy. Published content is not loaded until the learner enters
  /// a meaningful query. The resulting index is then reused for this service
  /// instance, so subsequent keystrokes do not trigger additional cloud reads.
  Future<List<StudyContentSearchResult>> search(
    String rawQuery, {
    int limit = 8,
  }) async {
    final query = _normalize(rawQuery);

    if (query.length < 2 || limit <= 0) {
      return const <StudyContentSearchResult>[];
    }

    final entries = await (_indexFuture ??= _buildIndex());
    final matches = <StudyContentSearchResult>[];

    for (final entry in entries) {
      final match = entry.match(query);

      if (match != null) {
        matches.add(match);
      }
    }

    matches.sort((left, right) {
      final scoreOrder = right.score.compareTo(left.score);

      if (scoreOrder != 0) {
        return scoreOrder;
      }

      final titleOrder = left.subtopicTitle.toLowerCase().compareTo(
        right.subtopicTitle.toLowerCase(),
      );

      if (titleOrder != 0) {
        return titleOrder;
      }

      return left.subtopicId.compareTo(right.subtopicId);
    });

    if (matches.length <= limit) {
      return List<StudyContentSearchResult>.unmodifiable(matches);
    }

    return List<StudyContentSearchResult>.unmodifiable(
      matches.take(limit).toList(),
    );
  }

  void clearMemoryIndex() {
    _indexFuture = null;
  }

  Future<List<_StudyContentSearchEntry>> _buildIndex() async {
    final published = await _loadPublishedContent();
    final entries = <_StudyContentSearchEntry>[];

    for (final content in published) {
      if (content.status.trim().toLowerCase() != 'published') {
        continue;
      }

      final domain = domainForContentId(content.domainId);
      final domainLabel = (domain?.id ?? content.domainId).toUpperCase();
      final domainTitle = domain?.title ?? content.domainId;

      for (final topic in content.topics) {
        for (final subtopic in topic.subtopics) {
          final fields = <_SearchField>[
            _SearchField(
              section: 'Subtopic',
              text: subtopic.title,
              weight: 1000,
            ),
            ...subtopic.learningObjectives.map(
              (value) => _SearchField(
                section: 'Learning objective',
                text: value,
                weight: 860,
              ),
            ),
            ..._visibleBlockStrings(subtopic.blocks).map(
              (value) => _SearchField(
                section: 'Main content',
                text: value,
                weight: 820,
              ),
            ),
            ...subtopic.keyPoints.map(
              (value) =>
                  _SearchField(section: 'Key point', text: value, weight: 780),
            ),
            ...subtopic.examples.map(
              (value) => _SearchField(
                section: 'Workplace example',
                text: value,
                weight: 740,
              ),
            ),
            ...subtopic.caseStudies.map(
              (value) =>
                  _SearchField(section: 'Case study', text: value, weight: 720),
            ),
            ...subtopic.formulas.map(
              (value) =>
                  _SearchField(section: 'Formula', text: value, weight: 700),
            ),
            ...subtopic.references.map(
              (value) =>
                  _SearchField(section: 'Reference', text: value, weight: 620),
            ),
            ...subtopic.examTips.map(
              (value) =>
                  _SearchField(section: 'Exam tip', text: value, weight: 760),
            ),
            ...subtopic.commonMistakes.map(
              (value) => _SearchField(
                section: 'Common mistake',
                text: value,
                weight: 730,
              ),
            ),
            ...subtopic.keyTakeaways.map(
              (value) => _SearchField(
                section: 'Key takeaway',
                text: value,
                weight: 790,
              ),
            ),
          ].where((field) => field.text.trim().isNotEmpty).toList();

          if (fields.isEmpty) {
            continue;
          }

          entries.add(
            _StudyContentSearchEntry(
              domainId: content.domainId,
              domainLabel: domainLabel,
              domainTitle: domainTitle,
              competencyId: content.competencyId,
              competencyTitle: content.title,
              topicId: topic.id,
              topicTitle: topic.title,
              subtopicId: subtopic.id,
              subtopicTitle: subtopic.title,
              fields: fields,
            ),
          );
        }
      }
    }

    return List<_StudyContentSearchEntry>.unmodifiable(entries);
  }

  static Iterable<String> _visibleBlockStrings(
    List<ContentBlock> blocks,
  ) sync* {
    for (final block in blocks) {
      if (_isHiddenSourceTraceabilityReference(block)) {
        continue;
      }

      yield* _flattenVisibleValues(block.data);
    }
  }

  static bool _isHiddenSourceTraceabilityReference(ContentBlock block) {
    if (block.type.trim().toLowerCase() != 'reference') {
      return false;
    }

    final title = block.data['title']?.toString().trim().toLowerCase() ?? '';
    final normalizedTitle = title.replaceAll(RegExp(r'\s+'), ' ');

    return normalizedTitle == 'csp source traceability';
  }

  static Iterable<String> _flattenVisibleValues(dynamic value) sync* {
    if (value == null) {
      return;
    }

    if (value is String) {
      final text = value.trim();

      if (text.isNotEmpty) {
        yield text;
      }

      return;
    }

    if (value is Iterable) {
      for (final item in value) {
        yield* _flattenVisibleValues(item);
      }

      return;
    }

    if (value is Map) {
      for (final item in value.values) {
        yield* _flattenVisibleValues(item);
      }
    }
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('₀', '0')
        .replaceAll('₁', '1')
        .replaceAll('₂', '2')
        .replaceAll('₃', '3')
        .replaceAll('₄', '4')
        .replaceAll('₅', '5')
        .replaceAll('₆', '6')
        .replaceAll('₇', '7')
        .replaceAll('₈', '8')
        .replaceAll('₉', '9')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _StudyContentSearchEntry {
  final String domainId;
  final String domainLabel;
  final String domainTitle;
  final String competencyId;
  final String competencyTitle;
  final String topicId;
  final String topicTitle;
  final String subtopicId;
  final String subtopicTitle;
  final List<_SearchField> fields;

  const _StudyContentSearchEntry({
    required this.domainId,
    required this.domainLabel,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    required this.topicId,
    required this.topicTitle,
    required this.subtopicId,
    required this.subtopicTitle,
    required this.fields,
  });

  StudyContentSearchResult? match(String query) {
    _SearchField? bestField;
    var bestScore = -1;

    final queryTokens = query
        .split(' ')
        .where((token) => token.length >= 2)
        .toList(growable: false);

    for (final field in fields) {
      final normalized = StudyContentSearchService._normalize(field.text);

      if (normalized.isEmpty) {
        continue;
      }

      var score = -1;

      if (normalized == query) {
        score = field.weight + 500;
      } else if (normalized.startsWith(query)) {
        score = field.weight + 400;
      } else if (normalized.contains(query)) {
        score = field.weight + 300;
      } else if (queryTokens.isNotEmpty &&
          queryTokens.every(normalized.contains)) {
        score = field.weight + 120 + queryTokens.length;
      }

      if (score > bestScore) {
        bestScore = score;
        bestField = field;
      }
    }

    if (bestField == null) {
      return null;
    }

    return StudyContentSearchResult(
      domainId: domainId,
      domainLabel: domainLabel,
      domainTitle: domainTitle,
      competencyId: competencyId,
      competencyTitle: competencyTitle,
      topicId: topicId,
      topicTitle: topicTitle,
      subtopicId: subtopicId,
      subtopicTitle: subtopicTitle,
      matchSection: bestField.section,
      snippet: _snippet(bestField.text, query),
      score: bestScore,
    );
  }

  static String _snippet(String value, String normalizedQuery) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (compact.length <= 170) {
      return compact;
    }

    final lower = compact.toLowerCase();
    final rawTokens = normalizedQuery
        .split(' ')
        .where((item) => item.isNotEmpty);
    var index = lower.indexOf(normalizedQuery);

    if (index < 0) {
      for (final token in rawTokens) {
        index = lower.indexOf(token);

        if (index >= 0) {
          break;
        }
      }
    }

    if (index < 0) {
      return '${compact.substring(0, 167).trimRight()}…';
    }

    final start = index > 55 ? index - 55 : 0;
    final desiredEnd = index + normalizedQuery.length + 105;
    final end = desiredEnd < compact.length ? desiredEnd : compact.length;

    var snippet = compact.substring(start, end).trim();

    if (start > 0) {
      snippet = '…$snippet';
    }

    if (end < compact.length) {
      snippet = '$snippet…';
    }

    return snippet;
  }
}

class _SearchField {
  final String section;
  final String text;
  final int weight;

  const _SearchField({
    required this.section,
    required this.text,
    required this.weight,
  });
}
