import 'dart:convert';

import 'package:crypto/crypto.dart';

class StartupTextMetrics {
  const StartupTextMetrics._();

  static final RegExp _wordPattern = RegExp(
    r"[A-Za-z0-9]+(?:[/'-][A-Za-z0-9]+)*",
  );

  static int wordCount(String value) => _wordPattern.allMatches(value).length;

  static int sentenceCount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 0;
    }

    var count = 0;
    for (final match in RegExp(r'[.!?]+(?=\s|$)').allMatches(trimmed)) {
      if (match.group(0)?.isNotEmpty ?? false) {
        count++;
      }
    }
    return count == 0 ? 1 : count;
  }

  static int readSeconds(String value, int wordsPerMinute) {
    final words = wordCount(value);
    if (words == 0) {
      return 0;
    }
    return ((words * 60) / wordsPerMinute).ceil();
  }

  static String sha256Text(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static int parentheticalGroupCount(String value) =>
      '('.allMatches(value).length;

  static bool hasNewline(String value) =>
      value.contains('\n') || value.contains('\r');

  static bool hasTab(String value) => value.contains('\t');

  static bool hasRepeatedWhitespace(String value) =>
      RegExp(r' {2,}').hasMatch(value);

  static bool hasHtml(String value) =>
      RegExp(r'<[^>]+>').hasMatch(value);

  static bool hasMarkdownLink(String value) =>
      RegExp(r'\[[^\]]+\]\([^)]+\)').hasMatch(value);

  static bool hasRawUrl(String value) => RegExp(
    r'(https?://|www\.)',
    caseSensitive: false,
  ).hasMatch(value);

  static bool hasBulletPrefix(String value) => RegExp(
    r'^\s*(?:[-*•]|\d+[.)])\s+',
    multiLine: true,
  ).hasMatch(value);

  static bool hasSourceLabelPrefix(String value) => RegExp(
    r'^\s*(?:source|reference|ref|citation)\s*:',
    caseSensitive: false,
  ).hasMatch(value);

  static bool hasRepeatedPunctuation(String value) =>
      RegExp(r'[!?.,;:]{2,}').hasMatch(value);

  static bool hasEmoji(String value) {
    for (final rune in value.runes) {
      if ((rune >= 0x1F300 && rune <= 0x1FAFF) ||
          (rune >= 0x2600 && rune <= 0x27BF)) {
        return true;
      }
    }
    return false;
  }

  static Set<String> uppercaseTokens(String value) {
    return RegExp(r'\b[A-Z][A-Z0-9-]{1,}\b')
        .allMatches(value)
        .map((match) => match.group(0)!)
        .toSet();
  }

  static bool containsAnyPhrase(String value, Iterable<String> phrases) {
    final normalized = value.toLowerCase();
    return phrases.any(
      (phrase) => normalized.contains(phrase.toLowerCase()),
    );
  }

  static bool containsAnswerKeyLanguage(String value) => RegExp(
    r'\b(?:the\s+)?(?:correct|best)\s+answer\s+(?:is|would\s+be)\b|'
    r'\boption\s+[abcd]\s+(?:is|would\s+be)\b|'
    r'\bchoose\s+option\s+[abcd]\b',
    caseSensitive: false,
  ).hasMatch(value);
}
