import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'SharedPreferences repository stores packages in sharded keys',
    () async {
      const codec = FlashcardPackageJsonCodec();
      final contentPackage = codec.decode(
        File(
          'assets/flashcards/run3/fc_reference_package.v1.json',
        ).readAsStringSync(),
      );
      final repository = SharedPreferencesFlashcardPackageRepository();

      await repository.savePackage(contentPackage);

      expect(await repository.listPackageIds(), <String>[
        'd03_c02_flashcards_v1',
      ]);

      final loaded = await repository.loadPackage('d03_c02_flashcards_v1');
      expect(loaded, isNotNull);
      expect(loaded!.cards, hasLength(2));

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          'csp11.flashcards.package.v1.d03_c02_flashcards_v1',
        ),
        isNotNull,
      );
      expect(
        preferences.getStringList('csp11.flashcards.package.index.v1'),
        <String>['d03_c02_flashcards_v1'],
      );

      await repository.deletePackage('d03_c02_flashcards_v1');
      expect(await repository.listPackageIds(), isEmpty);
      expect(await repository.loadPackage('d03_c02_flashcards_v1'), isNull);
    },
  );
}
