import 'flashcard_source_provenance.dart';

class FlashcardSourceRef {
  const FlashcardSourceRef({
    required this.sourceId,
    this.locator = '',
    this.primary = false,
    this.definitionMode = SourceDefinitionMode.educationalParaphrase,
  });

  final String sourceId;
  final String locator;
  final bool primary;
  final SourceDefinitionMode definitionMode;

  factory FlashcardSourceRef.fromJson(Map<String, dynamic> json) {
    return FlashcardSourceRef(
      sourceId: json['sourceId']?.toString() ?? '',
      locator: json['locator']?.toString() ?? '',
      primary: json['primary'] == true,
      definitionMode: sourceDefinitionModeFromJson(json['definitionMode']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      if (locator.isNotEmpty) 'locator': locator,
      'primary': primary,
      'definitionMode': definitionMode.name,
    };
  }
}
