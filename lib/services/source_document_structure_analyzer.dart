import '../models/source_extraction_result.dart';
import '../models/source_structure_node.dart';

class SourceDocumentStructureAnalyzer {
  const SourceDocumentStructureAnalyzer();

  List<SourceStructureNode> analyze(
    SourceExtractionResult extraction,
  ) {
    final nodes = <SourceStructureNode>[];

    for (final page in extraction.pages) {
      final lines = page.text
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      var paragraphBuffer = <String>[];

      void flushParagraph() {
        if (paragraphBuffer.isEmpty) return;
        final text = paragraphBuffer.join(' ');
        nodes.add(
          SourceStructureNode(
            id: '${extraction.sourceId}_${page.pageNumber}_${nodes.length}',
            type: SourceStructureNodeType.paragraph,
            title: '',
            text: text,
            pageNumber: page.pageNumber,
            depth: 3,
          ),
        );
        paragraphBuffer = [];
      }

      for (final line in lines) {
        if (_looksLikeHeading(line)) {
          flushParagraph();
          nodes.add(
            SourceStructureNode(
              id: '${extraction.sourceId}_${page.pageNumber}_${nodes.length}',
              type: _headingType(line),
              title: _cleanHeading(line),
              text: '',
              pageNumber: page.pageNumber,
              depth: _headingDepth(line),
            ),
          );
        } else if (_looksLikeList(line)) {
          flushParagraph();
          nodes.add(
            SourceStructureNode(
              id: '${extraction.sourceId}_${page.pageNumber}_${nodes.length}',
              type: SourceStructureNodeType.list,
              title: '',
              text: line,
              pageNumber: page.pageNumber,
              depth: 3,
            ),
          );
        } else {
          paragraphBuffer.add(line);
        }
      }

      flushParagraph();
    }

    return nodes;
  }

  bool _looksLikeHeading(String line) {
    if (line.length > 140) return false;
    if (RegExp(r'^(chapter|section)\s+\d+', caseSensitive: false)
        .hasMatch(line)) {
      return true;
    }
    if (RegExp(r'^\d+(\.\d+)*\s+\S+').hasMatch(line)) {
      return true;
    }
    return line == line.toUpperCase() && line.length > 3;
  }

  bool _looksLikeList(String line) =>
      RegExp(r'^([-•*]|\d+[.)])\s+').hasMatch(line);

  SourceStructureNodeType _headingType(String line) {
    if (RegExp(r'^chapter\s+', caseSensitive: false).hasMatch(line)) {
      return SourceStructureNodeType.chapter;
    }
    if (RegExp(r'^\d+\.\d+\.').hasMatch(line)) {
      return SourceStructureNodeType.subsection;
    }
    return SourceStructureNodeType.section;
  }

  int _headingDepth(String line) {
    final match = RegExp(r'^(\d+(?:\.\d+)*)').firstMatch(line);
    if (match == null) return 1;
    return match.group(1)!.split('.').length;
  }

  String _cleanHeading(String line) =>
      line.replaceFirst(RegExp(r'^[-•*]\s+'), '').trim();
}
