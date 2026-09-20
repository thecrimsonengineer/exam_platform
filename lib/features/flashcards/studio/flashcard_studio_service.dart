import '../io/flashcard_package_json_codec.dart';
import '../models/fcq_validation_result.dart';
import '../models/flashcard_content_package.dart';
import '../models/flashcard_deck_index.dart';
import '../reports/flashcard_mapping_coverage_report.dart';
import '../repository/flashcard_package_repository.dart';
import '../validation/fcq100_validator.dart';
import '../validation/flashcard_deck_validator.dart';

class FlashcardStudioImportResult {
  const FlashcardStudioImportResult({
    required this.contentPackage,
    required this.fcq,
  });

  final FlashcardContentPackage contentPackage;
  final FcqValidationResult fcq;
}

class FlashcardStudioService {
  FlashcardStudioService({
    required FlashcardPackageRepository repository,
    FlashcardPackageJsonCodec codec = const FlashcardPackageJsonCodec(),
    Fcq100Validator fcq100 = const Fcq100Validator(),
    FlashcardDeckValidator deckValidator = const FlashcardDeckValidator(),
  }) : _repository = repository,
       _codec = codec,
       _fcq100 = fcq100,
       _deckValidator = deckValidator;

  final FlashcardPackageRepository _repository;
  final FlashcardPackageJsonCodec _codec;
  final Fcq100Validator _fcq100;
  final FlashcardDeckValidator _deckValidator;

  FlashcardStudioImportResult importJson(String source) {
    final contentPackage = _codec.decode(source);
    final structure = _deckValidator.validate(contentPackage);
    if (!structure.passed) {
      throw FormatException(
        'Flashcard package structure failed: ${structure.issues.join(' | ')}',
      );
    }

    return FlashcardStudioImportResult(
      contentPackage: contentPackage,
      fcq: _fcq100.validate(contentPackage),
    );
  }

  FcqValidationResult validateForBundling(
    FlashcardContentPackage contentPackage,
  ) {
    return _fcq100.validate(contentPackage);
  }

  Future<void> savePackage(FlashcardContentPackage contentPackage) async {
    final structure = _deckValidator.validate(contentPackage);
    if (!structure.passed) {
      throw FormatException(
        'Flashcard package structure failed: ${structure.issues.join(' | ')}',
      );
    }
    await _repository.savePackage(contentPackage);
  }

  Future<String> exportJson(String packageId) async {
    final contentPackage = await _repository.loadPackage(packageId);
    if (contentPackage == null) {
      throw StateError('Flashcard package not found: $packageId');
    }
    return _codec.encode(contentPackage);
  }

  Future<FlashcardDeckIndex> buildDeckIndex() async {
    final ids = await _repository.listPackageIds();
    final entries = <FlashcardDeckIndexEntry>[];

    for (final id in ids) {
      final contentPackage = await _repository.loadPackage(id);
      if (contentPackage != null) {
        entries.add(FlashcardDeckIndexEntry.fromPackage(contentPackage));
      }
    }

    entries.sort((a, b) => a.deckId.compareTo(b.deckId));
    return FlashcardDeckIndex(List.unmodifiable(entries));
  }

  Future<FlashcardMappingCoverageReport> mappingCoverage(
    String packageId, {
    Iterable<int> eligibleQuestionIds = const <int>[],
  }) async {
    final contentPackage = await _repository.loadPackage(packageId);
    if (contentPackage == null) {
      throw StateError('Flashcard package not found: $packageId');
    }

    return FlashcardMappingCoverageReport.build(
      package: contentPackage,
      eligibleQuestionIds: eligibleQuestionIds,
    );
  }

  Future<void> deletePackage(String packageId) {
    return _repository.deletePackage(packageId);
  }
}
