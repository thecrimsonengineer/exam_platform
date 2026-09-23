import 'package:exam_platform/services/micro_learning/startup_text_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('word count keeps slash and apostrophe safety terms together', () {
    expect(
      StartupTextMetrics.wordCount(
        "OSHA's lockout/tagout standard addresses hazardous energy.",
      ),
      6,
    );
  });

  test('sentence count handles compact startup copy', () {
    expect(
      StartupTextMetrics.sentenceCount(
        'Elimination removes the hazard. PPE reduces exposure.',
      ),
      2,
    );
  });

  test('150 wpm read time rounds up deterministically', () {
    expect(
      StartupTextMetrics.readSeconds(
        'one two three four five six seven eight',
        150,
      ),
      4,
    );
  });

  test('SHA-256 fingerprint is deterministic', () {
    expect(
      StartupTextMetrics.sha256Text('CSP11'),
      StartupTextMetrics.sha256Text('CSP11'),
    );
    expect(
      StartupTextMetrics.sha256Text('CSP11'),
      isNot(StartupTextMetrics.sha256Text('CSP12')),
    );
  });

  test('plain-text hazards are detected', () {
    expect(StartupTextMetrics.hasNewline('line one\nline two'), isTrue);
    expect(StartupTextMetrics.hasTab('one\ttwo'), isTrue);
    expect(StartupTextMetrics.hasHtml('<b>fact</b>'), isTrue);
    expect(
      StartupTextMetrics.hasMarkdownLink('[OSHA](https://osha.gov)'),
      isTrue,
    );
    expect(
      StartupTextMetrics.hasRawUrl('Read https://www.osha.gov now'),
      isTrue,
    );
    expect(StartupTextMetrics.hasBulletPrefix('• Hazard control'), isTrue);
    expect(StartupTextMetrics.hasSourceLabelPrefix('Source: OSHA'), isTrue);
    expect(StartupTextMetrics.hasRepeatedWhitespace('two  spaces'), isTrue);
    expect(StartupTextMetrics.hasRepeatedPunctuation('Really??'), isTrue);
  });

  test('visual-dependency and answer-key phrases are detectable', () {
    expect(
      StartupTextMetrics.containsAnyPhrase('Tap the highlighted icon.', const [
        'tap the',
        'the highlighted',
      ]),
      isTrue,
    );
    expect(
      StartupTextMetrics.containsAnswerKeyLanguage(
        'The correct answer is option B.',
      ),
      isTrue,
    );
  });
}
