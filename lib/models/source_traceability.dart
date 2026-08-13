class SourceTraceability {
  final String id;
  final String sourceId;
  final String sourceNodeId;
  final int? pageNumber;
  final String? sectionTitle;
  final String passage;
  final String targetType;
  final String targetId;
  final DateTime createdAt;

  const SourceTraceability({
    required this.id,
    required this.sourceId,
    required this.sourceNodeId,
    this.pageNumber,
    this.sectionTitle,
    required this.passage,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'sourceNodeId': sourceNodeId,
        'pageNumber': pageNumber,
        'sectionTitle': sectionTitle,
        'passage': passage,
        'targetType': targetType,
        'targetId': targetId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SourceTraceability.fromJson(
    Map<String, dynamic> json,
  ) {
    return SourceTraceability(
      id: json['id']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      sourceNodeId: json['sourceNodeId']?.toString() ?? '',
      pageNumber: json['pageNumber'] is int
          ? json['pageNumber'] as int
          : int.tryParse(json['pageNumber']?.toString() ?? ''),
      sectionTitle: json['sectionTitle']?.toString(),
      passage: json['passage']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
