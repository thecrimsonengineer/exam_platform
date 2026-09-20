import 'flashcard_lifecycle.dart';
import 'flashcard_placement.dart';
import 'flashcard_source_ref.dart';
import 'flashcard_type.dart';

class Flashcard {
  const Flashcard({
    required this.id,
    required this.conceptId,
    required this.version,
    required this.type,
    required this.frontLabel,
    required this.backDefinition,
    required this.primaryPlacement,
    this.whyItMatters = '',
    this.keyPoint = '',
    this.sourceRefs = const <FlashcardSourceRef>[],
    this.lifecycle = FlashcardLifecycle.candidate,
    this.tags = const <String>[],
  });

  final String id;
  final String conceptId;
  final int version;
  final FlashcardType type;

  /// Learner-facing front. This is a concept/term/phrase, never a question.
  final String frontLabel;

  /// Core learner-facing meaning shown after reveal.
  final String backDefinition;

  final String whyItMatters;
  final String keyPoint;
  final FlashcardPlacement primaryPlacement;

  /// Reserved structurally in Run 1. Run 2 makes provenance authoritative.
  final List<FlashcardSourceRef> sourceRefs;

  final FlashcardLifecycle lifecycle;
  final List<String> tags;

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final rawPlacement = json['primaryPlacement'];
    if (rawPlacement is! Map) {
      throw const FormatException('Flashcard primaryPlacement is required.');
    }

    final rawSources = json['sourceRefs'];
    final rawTags = json['tags'];

    return Flashcard(
      id: json['id']?.toString() ?? '',
      conceptId: json['conceptId']?.toString() ?? '',
      version: _toInt(json['version'], fallback: 1),
      type: flashcardTypeFromJson(json['type']),
      frontLabel: json['frontLabel']?.toString() ?? '',
      backDefinition: json['backDefinition']?.toString() ?? '',
      whyItMatters: json['whyItMatters']?.toString() ?? '',
      keyPoint: json['keyPoint']?.toString() ?? '',
      primaryPlacement: FlashcardPlacement.fromJson(
        Map<String, dynamic>.from(rawPlacement),
      ),
      sourceRefs: rawSources is List
          ? rawSources
                .whereType<Map>()
                .map(
                  (item) => FlashcardSourceRef.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <FlashcardSourceRef>[],
      lifecycle: flashcardLifecycleFromJson(
        json['lifecycle'] ?? FlashcardLifecycle.candidate.name,
      ),
      tags: rawTags is List
          ? rawTags
                .map((item) => item?.toString().trim() ?? '')
                .where((item) => item.isNotEmpty)
                .toList()
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conceptId': conceptId,
      'version': version,
      'type': type.name,
      'frontLabel': frontLabel,
      'backDefinition': backDefinition,
      if (whyItMatters.isNotEmpty) 'whyItMatters': whyItMatters,
      if (keyPoint.isNotEmpty) 'keyPoint': keyPoint,
      'primaryPlacement': primaryPlacement.toJson(),
      'sourceRefs': sourceRefs.map((source) => source.toJson()).toList(),
      'lifecycle': lifecycle.name,
      'tags': tags,
    };
  }
}

int _toInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
