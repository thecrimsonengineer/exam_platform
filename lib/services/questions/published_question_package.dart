import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../models/question.dart';

class PublishedQuestionPackageDescriptor {
  const PublishedQuestionPackageDescriptor({
    required this.competencyId,
    required this.version,
    required this.checksumSha256,
    required this.compressedBytes,
    required this.publishedQuestionCount,
    this.ultraHardCount = 0,
  });

  final String competencyId;
  final int version;
  final String checksumSha256;
  final int compressedBytes;
  final int publishedQuestionCount;
  final int ultraHardCount;

  factory PublishedQuestionPackageDescriptor.fromJson(
    Map<String, dynamic> json,
  ) {
    final competencyId = _requiredString(json, 'competencyId');
    if (!_competencyPattern.hasMatch(competencyId)) {
      throw const FormatException('Invalid question-package competency ID.');
    }

    final checksum = _requiredString(json, 'questionChecksumSha256')
        .toLowerCase();
    if (!_sha256Pattern.hasMatch(checksum)) {
      throw const FormatException('Invalid question-package SHA-256.');
    }

    return PublishedQuestionPackageDescriptor(
      competencyId: competencyId,
      version: _requiredPositiveInt(json, 'questionVersion'),
      checksumSha256: checksum,
      compressedBytes: _requiredNonNegativeInt(json, 'questionSizeBytes'),
      publishedQuestionCount: _requiredNonNegativeInt(
        json,
        'publishedQuestionCount',
      ),
      ultraHardCount: _optionalNonNegativeInt(json['ultraHardCount']),
    );
  }

  Map<String, dynamic> toKnownRequestJson() => <String, dynamic>{
    'competencyId': competencyId,
    'knownQuestionVersion': version,
    'knownQuestionChecksumSha256': checksumSha256,
  };
}

class QuestionPackageResolution {
  const QuestionPackageResolution({
    required this.descriptor,
    required this.current,
    this.signedUrl,
  });

  final PublishedQuestionPackageDescriptor descriptor;
  final bool current;
  final Uri? signedUrl;

  factory QuestionPackageResolution.fromJson(Map<String, dynamic> json) {
    final descriptor = PublishedQuestionPackageDescriptor.fromJson(json);
    final current = json['current'];

    if (current is! bool) {
      throw const FormatException(
        'Question-package resolution must include current.',
      );
    }

    final rawSignedUrl = json['signedUrl']?.toString().trim();
    final signedUrl = rawSignedUrl == null || rawSignedUrl.isEmpty
        ? null
        : Uri.tryParse(rawSignedUrl);

    if (current && signedUrl != null) {
      throw const FormatException(
        'A current question package must not include a signed URL.',
      );
    }

    if (!current &&
        (signedUrl == null ||
            !signedUrl.hasScheme ||
            signedUrl.scheme.toLowerCase() != 'https')) {
      throw const FormatException(
        'A changed question package requires a valid HTTPS signed URL.',
      );
    }

    return QuestionPackageResolution(
      descriptor: descriptor,
      current: current,
      signedUrl: signedUrl,
    );
  }
}

class VerifiedQuestionPackage {
  const VerifiedQuestionPackage({
    required this.descriptor,
    required this.questions,
  });

  final PublishedQuestionPackageDescriptor descriptor;
  final List<Question> questions;
}

class QuestionPackageDecoder {
  const QuestionPackageDecoder();

  VerifiedQuestionPackage decode({
    required PublishedQuestionPackageDescriptor descriptor,
    required List<int> compressedBytes,
  }) {
    if (compressedBytes.length != descriptor.compressedBytes) {
      throw const FormatException(
        'Question package compressed byte count does not match metadata.',
      );
    }

    final compressed = Uint8List.fromList(compressedBytes);
    final checksum = sha256.convert(compressed).toString();

    if (checksum != descriptor.checksumSha256) {
      throw const FormatException('Question package SHA-256 mismatch.');
    }

    late final List<int> decodedBytes;

    try {
      decodedBytes = GZipDecoder().decodeBytes(compressed);
    } catch (_) {
      throw const FormatException('Question package gzip decoding failed.');
    }

    late final Object? decodedJson;

    try {
      decodedJson = jsonDecode(utf8.decode(decodedBytes));
    } catch (_) {
      throw const FormatException('Question package JSON decoding failed.');
    }

    if (decodedJson is! Map) {
      throw const FormatException('Question package root must be an object.');
    }

    final envelope = Map<String, dynamic>.from(decodedJson);

    if (_requiredInt(envelope, 'schemaVersion') != 1) {
      throw const FormatException('Unsupported question package schema.');
    }

    if (_requiredString(envelope, 'kind') != 'questions') {
      throw const FormatException('Question package kind must be questions.');
    }

    if (_requiredString(envelope, 'competencyId') != descriptor.competencyId) {
      throw const FormatException('Question package competency mismatch.');
    }

    final declaredCount = _requiredNonNegativeInt(envelope, 'questionCount');
    final rawQuestions = envelope['questions'];

    if (rawQuestions is! List || rawQuestions.length != declaredCount) {
      throw const FormatException(
        'Question package declared count does not match payload.',
      );
    }

    if (declaredCount != descriptor.publishedQuestionCount) {
      throw const FormatException(
        'Question package count does not match catalogue metadata.',
      );
    }

    final questionIds = <int>{};
    final questions = <Question>[];

    for (final rawQuestion in rawQuestions) {
      if (rawQuestion is! Map) {
        throw const FormatException(
          'Question package entries must be objects.',
        );
      }

      final json = Map<String, dynamic>.from(rawQuestion);
      final id = _requiredPositiveInt(json, 'id');

      if (!questionIds.add(id)) {
        throw const FormatException(
          'Question package contains duplicate question IDs.',
        );
      }

      if (_requiredString(json, 'competencyId') != descriptor.competencyId) {
        throw const FormatException(
          'Question package contains a cross-competency question.',
        );
      }

      final status = _requiredString(json, 'status').toLowerCase();
      if (status != 'published') {
        throw const FormatException(
          'Question package contains a non-published question.',
        );
      }

      final options = json['options'];
      if (options is! List || options.length != 4) {
        throw const FormatException(
          'Question package questions must contain exactly four options.',
        );
      }

      final correctAnswer = _requiredInt(json, 'correctAnswer');
      if (correctAnswer < 0 || correctAnswer > 3) {
        throw const FormatException(
          'Question package correct answer must be in the range 0-3.',
        );
      }

      late final Question question;

      try {
        question = Question.fromJson(json);
      } catch (_) {
        throw const FormatException('Question package question is invalid.');
      }

      if (question.id != id ||
          question.competencyId != descriptor.competencyId ||
          question.status.trim().toLowerCase() != 'published' ||
          question.options.length != 4 ||
          question.correctAnswer < 0 ||
          question.correctAnswer > 3) {
        throw const FormatException(
          'Question package normalized question failed validation.',
        );
      }

      questions.add(question);
    }

    questions.sort((left, right) => left.id.compareTo(right.id));

    return VerifiedQuestionPackage(
      descriptor: descriptor,
      questions: List<Question>.unmodifiable(questions),
    );
  }
}

final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final RegExp _competencyPattern = RegExp(
  r'^d\d{2}_c\d{2}$',
  caseSensitive: false,
);

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();

  if (value == null || value.isEmpty) {
    throw FormatException('Missing required string "$key".');
  }

  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is int) {
    return value;
  }

  if (value is num && value == value.toInt()) {
    return value.toInt();
  }

  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('Missing required integer "$key".');
  }

  return parsed;
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final value = _requiredInt(json, key);
  if (value <= 0) {
    throw FormatException('"$key" must be positive.');
  }
  return value;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final value = _requiredInt(json, key);
  if (value < 0) {
    throw FormatException('"$key" cannot be negative.');
  }
  return value;
}

int _optionalNonNegativeInt(Object? value) {
  if (value == null) {
    return 0;
  }

  final parsed = value is int ? value : int.tryParse(value.toString());
  if (parsed == null || parsed < 0) {
    throw const FormatException('Optional count cannot be negative.');
  }

  return parsed;
}
