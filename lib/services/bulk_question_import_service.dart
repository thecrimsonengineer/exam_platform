import '../models/question_entry_draft.dart';

class BulkQuestionImportService {
  const BulkQuestionImportService();

  List<QuestionEntryDraft> parse(String input) {
    final blocks = input
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);

    return List.unmodifiable(
      blocks
          .map(_parseBlock)
          .whereType<QuestionEntryDraft>(),
    );
  }

  QuestionEntryDraft? _parseBlock(String block) {
    String? stem;
    final options = <String>[];
    String? bestAnswer;
    String? explanation;
    String? reference;
    final tags = <String>[];
    String? difficulty;
    String? cognitiveLevel;

    String? field;

    for (final raw in block.split('\n')) {
      final line = raw.trim();

      if (line.startsWith('QUESTION:')) {
        stem = _value(line);
        field = 'stem';
        continue;
      }

      if (RegExp(r'^[A-D]:').hasMatch(line)) {
        options.add(_value(line));
        field = null;
        continue;
      }

      if (line.startsWith('BEST ANSWER:')) {
        bestAnswer = _value(line);
        field = null;
        continue;
      }

      if (line.startsWith('EXPLANATION:')) {
        explanation = _value(line);
        field = 'explanation';
        continue;
      }

      if (line.startsWith('REFERENCE:')) {
        reference = _value(line);
        field = 'reference';
        continue;
      }

      if (line.startsWith('TAGS:')) {
        tags.addAll(
          _value(line)
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty),
        );
        field = null;
        continue;
      }

      if (line.startsWith('DIFFICULTY:')) {
        difficulty = _value(line);
        field = null;
        continue;
      }

      if (line.startsWith('COGNITIVE LEVEL:')) {
        cognitiveLevel = _value(line);
        field = null;
        continue;
      }

      if (field == 'stem') {
        stem = _append(stem, raw);
      } else if (field == 'explanation') {
        explanation = _append(explanation, raw);
      } else if (field == 'reference') {
        reference = _append(reference, raw);
      }
    }

    if (stem == null || bestAnswer == null || explanation == null) {
      return null;
    }

    return QuestionEntryDraft(
      stem: stem!.trim(),
      options: List.unmodifiable(options),
      bestAnswer: bestAnswer!.trim(),
      explanation: explanation!.trim(),
      reference: _nullable(reference),
      tags: List.unmodifiable(tags),
      difficulty: _nullable(difficulty),
      cognitiveLevel: _nullable(cognitiveLevel),
    );
  }

  String _value(String line) {
    final index = line.indexOf(':');
    return index == -1 ? '' : line.substring(index + 1).trim();
  }

  String? _append(String? current, String value) {
    final item = value.trim();
    if (item.isEmpty) {
      return current;
    }
    if (current == null || current!.isEmpty) {
      return item;
    }
    return '$current\n$item';
  }

  String? _nullable(String? value) {
    final item = value?.trim();
    return item == null || item.isEmpty ? null : item;
  }
}
