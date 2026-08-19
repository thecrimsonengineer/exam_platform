import '../models/content_entry_draft.dart';

class OnePasteContentParser {
  const OnePasteContentParser();

  ContentEntryDraft parse(String input) {
    final lines = input.replaceAll('\r\n', '\n').split('\n');

    String? domainId;
    String? competencyId;
    String? subtopicTitle;

    final topics = <ContentTopicDraft>[];
    _TopicBuffer? current;

    void flushTopic() {
      if (current == null) {
        return;
      }

      final buffer = current!;
      if (buffer.title.trim().isNotEmpty) {
        topics.add(
          ContentTopicDraft(
            title: buffer.title.trim(),
            content: buffer.content.trim(),
            keyPoints: List.unmodifiable(
              buffer.keyPoints
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty),
            ),
            example: _nullable(buffer.example),
            examTip: _nullable(buffer.examTip),
            reference: _nullable(buffer.reference),
          ),
        );
      }

      current = null;
    }

    String? activeField;
    final contentLines = <String>[];

    void commitContentLines() {
      if (current == null || contentLines.isEmpty) {
        contentLines.clear();
        return;
      }

      current!.content = [
        current!.content,
        ...contentLines,
      ].where((item) => item.trim().isNotEmpty).join('\n').trim();

      contentLines.clear();
    }

    for (final raw in lines) {
      final line = raw.trim();

      if (line.startsWith('DOMAIN:')) {
        commitContentLines();
        domainId = _value(line);
        activeField = null;
        continue;
      }

      if (line.startsWith('COMPETENCY:')) {
        commitContentLines();
        competencyId = _value(line);
        activeField = null;
        continue;
      }

      if (line.startsWith('SUBTOPIC:')) {
        commitContentLines();
        subtopicTitle = _value(line);
        activeField = null;
        continue;
      }

      if (line.startsWith('TOPIC:')) {
        commitContentLines();
        flushTopic();
        current = _TopicBuffer(title: _value(line));
        activeField = null;
        continue;
      }

      if (current == null) {
        continue;
      }

      if (line == 'CONTENT:') {
        commitContentLines();
        activeField = 'content';
        continue;
      }

      if (line == 'KEY POINTS:') {
        commitContentLines();
        activeField = 'keyPoints';
        continue;
      }

      if (line == 'EXAMPLE:') {
        commitContentLines();
        activeField = 'example';
        continue;
      }

      if (line == 'EXAM TIP:') {
        commitContentLines();
        activeField = 'examTip';
        continue;
      }

      if (line == 'REFERENCE:') {
        commitContentLines();
        activeField = 'reference';
        continue;
      }

      switch (activeField) {
        case 'content':
          contentLines.add(raw);
          break;
        case 'keyPoints':
          final point = line.replaceFirst(RegExp(r'^[•\-*]\s*'), '');
          if (point.isNotEmpty) {
            current!.keyPoints.add(point);
          }
          break;
        case 'example':
          current!.example = _append(current!.example, raw);
          break;
        case 'examTip':
          current!.examTip = _append(current!.examTip, raw);
          break;
        case 'reference':
          current!.reference = _append(current!.reference, raw);
          break;
      }
    }

    commitContentLines();
    flushTopic();

    return ContentEntryDraft(
      domainId: _nullable(domainId),
      competencyId: _nullable(competencyId),
      subtopicTitle: _nullable(subtopicTitle),
      topics: List.unmodifiable(topics),
    );
  }

  String _value(String line) {
    final index = line.indexOf(':');
    if (index == -1) {
      return '';
    }
    return line.substring(index + 1).trim();
  }

  String? _append(String? current, String value) {
    final item = value.trim();
    if (item.isEmpty) {
      return current;
    }
    if (current == null || current.trim().isEmpty) {
      return item;
    }
    return '$current\n$item';
  }

  String? _nullable(String? value) {
    final item = value?.trim();
    return item == null || item.isEmpty ? null : item;
  }
}

class _TopicBuffer {
  String title;
  String content = '';
  final List<String> keyPoints = <String>[];
  String? example;
  String? examTip;
  String? reference;

  _TopicBuffer({required this.title});
}
