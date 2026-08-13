class Csp11ContentPack {
  final String packId;
  final String title;
  final List<Csp11ContentPackItem> items;

  const Csp11ContentPack({
    required this.packId,
    required this.title,
    required this.items,
  });
}

class Csp11ContentPackItem {
  final String domainId;
  final String competencyId;
  final String subtopicId;
  final String topicId;
  final String title;
  final String content;
  final String? sourceId;

  const Csp11ContentPackItem({
    required this.domainId,
    required this.competencyId,
    required this.subtopicId,
    required this.topicId,
    required this.title,
    required this.content,
    this.sourceId,
  });
}
