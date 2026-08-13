class ContentEntryDraft {
  final String? domainId;
  final String? competencyId;
  final String? subtopicTitle;
  final List<ContentTopicDraft> topics;

  const ContentEntryDraft({
    this.domainId,
    this.competencyId,
    this.subtopicTitle,
    required this.topics,
  });

  bool get hasTopics => topics.isNotEmpty;
}

class ContentTopicDraft {
  final String title;
  final String content;
  final List<String> keyPoints;
  final String? example;
  final String? examTip;
  final String? reference;

  const ContentTopicDraft({
    required this.title,
    required this.content,
    this.keyPoints = const [],
    this.example,
    this.examTip,
    this.reference,
  });
}
