import 'package:exam_platform/features/flashcards/models/flashcard.dart';
import 'package:exam_platform/features/flashcards/models/flashcard_placement.dart';
import 'package:exam_platform/features/flashcards/models/flashcard_source_provenance.dart';
import 'package:exam_platform/features/flashcards/models/flashcard_type.dart';
import 'package:exam_platform/screens/flashcards/widgets/flashcard_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = Flashcard(
    id: 'csp11.flashcard.pilot_b_accessibility',
    conceptId: 'csp11.concept.pilot_b_accessibility',
    version: 1,
    type: FlashcardType.concept,
    frontLabel: 'Pilot B accessibility',
    backDefinition: 'A bounded Flashcard accessibility test concept.',
    primaryPlacement: FlashcardPlacement(
      domainId: 'd01',
      competencyId: 'd01_c01',
    ),
  );

  const footer = FlashcardSourceFooter(
    sourceId: 'SRC-PILOT-B',
    label: 'Source: NIOSH',
    organization: 'NIOSH',
    locator: 'Pilot B test locator',
    url: 'https://www.cdc.gov/niosh/',
  );

  const sourceKey = ValueKey(
    'flashcard-source-csp11.flashcard.pilot_b_accessibility',
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    VoidCallback? onSourceTap,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlashcardCardView(
              card: card,
              isFlipped: true,
              sourceFooter: footer,
              onSourceTap: onSourceTap,
              compact: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'actionable source footer exposes button semantics and action hint',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;

      await pumpCard(
        tester,
        onSourceTap: () => taps++,
        themeMode: ThemeMode.light,
      );

      final sourceFinder = find.byKey(sourceKey);
      expect(sourceFinder, findsOneWidget);
      expect(find.text('Source: NIOSH'), findsOneWidget);
      expect(
        tester.getSemantics(sourceFinder),
        matchesSemantics(
          hint: 'Activate to view source details.',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await tester.tap(sourceFinder);
      await tester.pump();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'non-actionable source footer exposes neither button action nor hint',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpCard(tester, themeMode: ThemeMode.dark);

      final sourceFinder = find.byKey(sourceKey);
      expect(sourceFinder, findsOneWidget);
      expect(find.text('Source: NIOSH'), findsOneWidget);
      expect(
        tester.getSemantics(sourceFinder),
        matchesSemantics(
          hint: '',
          isButton: false,
          isFocusable: false,
          hasTapAction: false,
          hasFocusAction: false,
        ),
      );

      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
