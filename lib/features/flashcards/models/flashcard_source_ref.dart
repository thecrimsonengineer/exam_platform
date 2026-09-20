class FlashcardSourceRef {
  const FlashcardSourceRef({
    required this.sourceId,
    this.locator = '',
    this.primary = false,
  });

  final String sourceId;
  final String locator;
  final bool primary;

  factory FlashcardSourceRef.fromJson(Map<String, dynamic> json) {
    return FlashcardSourceRef(
      sourceId: json['sourceId']?.toString() ?? '',
      locator: json['locator']?.toString() ?? '',
      primary: json['primary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      if (locator.isNotEmpty) 'locator': locator,
      'primary': primary,
    };
  }
}
