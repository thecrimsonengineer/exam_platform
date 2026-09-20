import 'flashcard_lifecycle.dart';

class FlashcardDeck {
  const FlashcardDeck({
    required this.id,
    required this.domainId,
    required this.competencyId,
    required this.title,
    required this.version,
    this.lifecycle = FlashcardLifecycle.candidate,
    this.cardIds = const <String>[],
  });

  final String id;
  final String domainId;
  final String competencyId;
  final String title;
  final int version;
  final FlashcardLifecycle lifecycle;
  final List<String> cardIds;

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cardIds'];

    return FlashcardDeck(
      id: json['id']?.toString() ?? '',
      domainId: json['domainId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      version: _toInt(json['version'], fallback: 1),
      lifecycle: flashcardLifecycleFromJson(
        json['lifecycle'] ?? FlashcardLifecycle.candidate.name,
      ),
      cardIds: rawCards is List
          ? rawCards
                .map((item) => item?.toString().trim() ?? '')
                .where((item) => item.isNotEmpty)
                .toList()
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domainId': domainId,
      'competencyId': competencyId,
      'title': title,
      'version': version,
      'lifecycle': lifecycle.name,
      'cardIds': cardIds,
    };
  }
}

int _toInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
