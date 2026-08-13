class ContentImportRow {
  final int rowNumber;
  final String domainId;
  final String competencyId;
  final String subtopic;
  final String topic;
  final String content;
  final String keyPoints;
  final String example;
  final String examTip;
  final String reference;

  const ContentImportRow({
    required this.rowNumber,
    required this.domainId,
    required this.competencyId,
    required this.subtopic,
    required this.topic,
    required this.content,
    this.keyPoints = '',
    this.example = '',
    this.examTip = '',
    this.reference = '',
  });
}
