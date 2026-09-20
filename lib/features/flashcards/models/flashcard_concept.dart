import 'flashcard_placement.dart';

class FlashcardConcept {
  const FlashcardConcept({
    required this.id,
    required this.canonicalLabel,
    required this.flashcardId,
    required this.primaryPlacement,
    this.aliases = const <String>[],
  });

  final String id;
  final String canonicalLabel;
  final String flashcardId;
  final FlashcardPlacement primaryPlacement;
  final List<String> aliases;

  factory FlashcardConcept.fromJson(Map<String, dynamic> json) {
    final rawPlacement = json['primaryPlacement'];
    if (rawPlacement is! Map) {
      throw const FormatException('Concept primaryPlacement is required.');
    }

    final rawAliases = json['aliases'];

    return FlashcardConcept(
      id: json['id']?.toString() ?? '',
      canonicalLabel: json['canonicalLabel']?.toString() ?? '',
      flashcardId: json['flashcardId']?.toString() ?? '',
      primaryPlacement: FlashcardPlacement.fromJson(
        Map<String, dynamic>.from(rawPlacement),
      ),
      aliases: rawAliases is List
          ? rawAliases
                .map((item) => item?.toString().trim() ?? '')
                .where((item) => item.isNotEmpty)
                .toList()
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canonicalLabel': canonicalLabel,
      'flashcardId': flashcardId,
      'primaryPlacement': primaryPlacement.toJson(),
      'aliases': aliases,
    };
  }
}
