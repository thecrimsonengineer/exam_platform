import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

class PublishedFlashcardPackageDescriptor {
  const PublishedFlashcardPackageDescriptor({
    required this.competencyId,
    required this.version,
    required this.checksumSha256,
    required this.compressedBytes,
    required this.flashcardCount,
  });

  final String competencyId;
  final int version;
  final String checksumSha256;
  final int compressedBytes;
  final int flashcardCount;

  factory PublishedFlashcardPackageDescriptor.fromJson(
    Map<String, dynamic> json,
  ) {
    final competencyId = _requiredString(json, 'competencyId').toLowerCase();
    if (!_competencyPattern.hasMatch(competencyId)) {
      throw const FormatException('Invalid flashcard competency ID.');
    }

    final checksum = _requiredString(
      json,
      'flashcardChecksumSha256',
    ).toLowerCase();
    if (!_sha256Pattern.hasMatch(checksum)) {
      throw const FormatException('Invalid flashcard package SHA-256.');
    }

    return PublishedFlashcardPackageDescriptor(
      competencyId: competencyId,
      version: _requiredPositiveInt(json, 'flashcardVersion'),
      checksumSha256: checksum,
      compressedBytes: _requiredNonNegativeInt(json, 'flashcardSizeBytes'),
      flashcardCount: _requiredPositiveInt(json, 'flashcardCount'),
    );
  }

  Map<String, dynamic> toKnownRequestJson() => <String, dynamic>{
    'competencyId': competencyId,
    'knownFlashcardVersion': version,
    'knownFlashcardChecksumSha256': checksumSha256,
  };
}

class FlashcardPackageResolution {
  const FlashcardPackageResolution({
    required this.descriptor,
    required this.current,
    this.signedUrl,
  });

  final PublishedFlashcardPackageDescriptor descriptor;
  final bool current;
  final Uri? signedUrl;

  factory FlashcardPackageResolution.fromJson(Map<String, dynamic> json) {
    final descriptor = PublishedFlashcardPackageDescriptor.fromJson(json);
    final current = json['current'];
    if (current is! bool) {
      throw const FormatException(
        'Flashcard package resolution must include current.',
      );
    }

    final rawUrl = json['signedUrl']?.toString().trim();
    final signedUrl = rawUrl == null || rawUrl.isEmpty
        ? null
        : Uri.tryParse(rawUrl);

    if (current && signedUrl != null) {
      throw const FormatException(
        'A current flashcard package must not include a signed URL.',
      );
    }
    if (!current &&
        (signedUrl == null ||
            !signedUrl.hasScheme ||
            signedUrl.scheme.toLowerCase() != 'https')) {
      throw const FormatException(
        'A changed flashcard package requires a valid HTTPS signed URL.',
      );
    }

    return FlashcardPackageResolution(
      descriptor: descriptor,
      current: current,
      signedUrl: signedUrl,
    );
  }
}

class FlashcardCard {
  const FlashcardCard({
    required this.id,
    required this.frontLabel,
    required this.backDefinition,
    required this.whyItMatters,
    required this.keyPoint,
    required this.tags,
  });

  final String id;
  final String frontLabel;
  final String backDefinition;
  final String whyItMatters;
  final String keyPoint;
  final List<String> tags;

  factory FlashcardCard.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    if (tags is! List) {
      throw const FormatException('Flashcard tags must be a list.');
    }

    return FlashcardCard(
      id: _requiredString(json, 'id'),
      frontLabel: _requiredString(json, 'frontLabel'),
      backDefinition: _requiredString(json, 'backDefinition'),
      whyItMatters: _requiredString(json, 'whyItMatters'),
      keyPoint: _requiredString(json, 'keyPoint'),
      tags: List<String>.unmodifiable(
        tags
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty),
      ),
    );
  }
}

class FlashcardDeckPackage {
  const FlashcardDeckPackage({
    required this.competencyId,
    required this.domainId,
    required this.deckId,
    required this.title,
    required this.cards,
  });

  final String competencyId;
  final String domainId;
  final String deckId;
  final String title;
  final List<FlashcardCard> cards;
}

class VerifiedFlashcardPackage {
  const VerifiedFlashcardPackage({
    required this.descriptor,
    required this.package,
  });

  final PublishedFlashcardPackageDescriptor descriptor;
  final FlashcardDeckPackage package;
}

class FlashcardPackageDecoder {
  const FlashcardPackageDecoder();

  VerifiedFlashcardPackage decode({
    required PublishedFlashcardPackageDescriptor descriptor,
    required List<int> compressedBytes,
  }) {
    if (compressedBytes.length != descriptor.compressedBytes) {
      throw const FormatException(
        'Flashcard package compressed byte count does not match metadata.',
      );
    }

    final compressed = Uint8List.fromList(compressedBytes);
    if (sha256.convert(compressed).toString() != descriptor.checksumSha256) {
      throw const FormatException('Flashcard package SHA-256 mismatch.');
    }

    late final List<int> decodedBytes;
    try {
      decodedBytes = GZipDecoder().decodeBytes(compressed);
    } catch (_) {
      throw const FormatException('Flashcard package gzip decoding failed.');
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(decodedBytes));
    } catch (_) {
      throw const FormatException('Flashcard package JSON decoding failed.');
    }

    if (decoded is! Map) {
      throw const FormatException('Flashcard package root must be an object.');
    }

    final root = Map<String, dynamic>.from(decoded);
    if (_requiredString(root, 'schemaVersion') !=
        'csp11.flashcards.package.v1') {
      throw const FormatException('Unsupported flashcard package schema.');
    }

    final rawDeck = root['deck'];
    final rawCards = root['cards'];
    if (rawDeck is! Map || rawCards is! List) {
      throw const FormatException('Flashcard package structure is invalid.');
    }

    final deck = Map<String, dynamic>.from(rawDeck);
    final competencyId = _requiredString(deck, 'competencyId').toLowerCase();
    final domainId = _requiredString(deck, 'domainId').toLowerCase();

    if (competencyId != descriptor.competencyId ||
        domainId != competencyId.substring(0, 3)) {
      throw const FormatException('Flashcard package identity mismatch.');
    }

    final lifecycle = _requiredString(deck, 'lifecycle').toLowerCase();
    if (lifecycle != 'validated' && lifecycle != 'bundled') {
      throw const FormatException(
        'Flashcard package lifecycle is not learner-ready.',
      );
    }

    if (rawCards.length != descriptor.flashcardCount) {
      throw const FormatException(
        'Flashcard package count does not match catalogue metadata.',
      );
    }

    final ids = <String>{};
    final cards = <FlashcardCard>[];
    for (final raw in rawCards) {
      if (raw is! Map) {
        throw const FormatException('Flashcard entry must be an object.');
      }
      final cardJson = Map<String, dynamic>.from(raw);
      final placement = cardJson['primaryPlacement'];
      if (placement is! Map) {
        throw const FormatException('Flashcard placement is missing.');
      }
      final placementMap = Map<String, dynamic>.from(placement);
      if (_requiredString(placementMap, 'competencyId').toLowerCase() !=
              competencyId ||
          _requiredString(placementMap, 'domainId').toLowerCase() != domainId) {
        throw const FormatException(
          'Flashcard contains a cross-competency placement.',
        );
      }

      final card = FlashcardCard.fromJson(cardJson);
      if (!ids.add(card.id)) {
        throw const FormatException(
          'Flashcard package contains duplicate card IDs.',
        );
      }
      cards.add(card);
    }

    return VerifiedFlashcardPackage(
      descriptor: descriptor,
      package: FlashcardDeckPackage(
        competencyId: competencyId,
        domainId: domainId,
        deckId: _requiredString(deck, 'id'),
        title: _requiredString(deck, 'title'),
        cards: List<FlashcardCard>.unmodifiable(cards),
      ),
    );
  }
}

final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final RegExp _competencyPattern = RegExp(r'^d0[12]_c\d{2}$');

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();
  if (value == null || value.isEmpty) {
    throw FormatException('Missing required string "$key".');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num && value == value.toInt()) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('Missing required integer "$key".');
  }
  return parsed;
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final value = _requiredInt(json, key);
  if (value <= 0) throw FormatException('"$key" must be positive.');
  return value;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final value = _requiredInt(json, key);
  if (value < 0) throw FormatException('"$key" cannot be negative.');
  return value;
}
