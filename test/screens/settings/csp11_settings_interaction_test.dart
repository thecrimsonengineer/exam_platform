import 'package:exam_platform/screens/settings/settings_route.dart';
import 'package:exam_platform/screens/settings/settings_screen.dart';
import 'package:exam_platform/screens/settings/settings_screen_dark.dart';
import 'package:exam_platform/services/settings/theme_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'csp11.ui.dark_mode.v1': false,
    });
    await ThemeModeService.initialize();
  });

  tearDown(() {
    ThemeModeService.isDarkMode.value = true;
  });

  testWidgets('theme switch changes the visible Settings variant immediately', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsRoute()));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(DarkSettingsScreen), findsNothing);

    final tile = find.byKey(const ValueKey('settings-dark-mode'));
    await tester.scrollUntilVisible(tile, 350);

    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(ThemeModeService.isDarkMode.value, isTrue);
    expect(find.byType(DarkSettingsScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('sign out returns directly to the auth-root route', (tester) async {
    var signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(
                        signOutAction: () async {
                          signedOut = true;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('AUTH ROOT'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('AUTH ROOT'));
    await tester.pumpAndSettle();

    final signOutTile = find.byKey(const ValueKey('settings-sign-out'));
    await tester.scrollUntilVisible(signOutTile, 400);
    await tester.tap(signOutTile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('SIGN OUT'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
    expect(find.text('AUTH ROOT'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });
}
