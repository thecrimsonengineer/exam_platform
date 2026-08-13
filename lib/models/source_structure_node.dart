enum SourceStructureNodeType {
  document,
  chapter,
  section,
  subsection,
  paragraph,
  list,
  table,
}

class SourceStructureNode {
  final String id;
  final SourceStructureNodeType type;
  final String title;
  final String text;
  final int? pageNumber;
  final int depth;
  final List<SourceStructureNode> children;

  const SourceStructureNode({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    this.pageNumber,
    required this.depth,
    this.children = const [],
  });
}
