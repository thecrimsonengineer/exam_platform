import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/questions/published_question_package.dart';

void main() {
  group('FR9A question package gateway contracts', () {
    test('current package metadata refuses a signed URL', () {
      final resolution = QuestionPackageResolution.fromJson(
        _resolutionJson(current: true),
      );

      expect(resolution.current, isTrue);
      expect(resolution.signedUrl, isNull);
      expect(resolution.descriptor.competencyId, 'd01_c01');
      expect(resolution.descriptor.version, 3);
    });

    test('changed package requires an HTTPS signed URL', () {
      final resolution = QuestionPackageResolution.fromJson(
        _resolutionJson(
          current: false,
          signedUrl: 'https://example.supabase.co/storage/signed/package',
        ),
      );

      expect(resolution.current, isFalse);
      expect(resolution.signedUrl, isNotNull);
      expect(resolution.signedUrl!.scheme, 'https');
    });

    test('changed package rejects a missing signed URL', () {
      expect(
        () =>
            QuestionPackageResolution.fromJson(_resolutionJson(current: false)),
        throwsFormatException,
      );
    });

    test('catalog descriptor validates checksum and non-negative counts', () {
      expect(
        () => PublishedQuestionPackageDescriptor.fromJson(<String, dynamic>{
          ..._descriptorJson(),
          'questionChecksumSha256': 'bad-checksum',
        }),
        throwsFormatException,
      );

      expect(
        () => PublishedQuestionPackageDescriptor.fromJson(<String, dynamic>{
          ..._descriptorJson(),
          'publishedQuestionCount': -1,
        }),
        throwsFormatException,
      );
    });
  });

  group('FR9A strict question package decoder', () {
    test('accepts a valid FR7 question package', () {
      final package = _package();

      final verified = const QuestionPackageDecoder().decode(
        descriptor: package.descriptor,
        compressedBytes: package.bytes,
      );

      expect(verified.questions.map((question) => question.id), <int>[
        101,
        102,
      ]);
      expect(
        verified.questions.every(
          (question) =>
              question.competencyId == 'd01_c01' &&
              question.status == 'published',
        ),
        isTrue,
      );
    });

    test('rejects compressed byte-count mismatch', () {
      final package = _package();
      final descriptor = PublishedQuestionPackageDescriptor(
        competencyId: package.descriptor.competencyId,
        version: package.descriptor.version,
        checksumSha256: package.descriptor.checksumSha256,
        compressedBytes: package.descriptor.compressedBytes + 1,
        publishedQuestionCount: package.descriptor.publishedQuestionCount,
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects compressed SHA-256 mismatch', () {
      final package = _package();
      final descriptor = PublishedQuestionPackageDescriptor(
        competencyId: package.descriptor.competencyId,
        version: package.descriptor.version,
        checksumSha256: _hex64('0'),
        compressedBytes: package.descriptor.compressedBytes,
        publishedQuestionCount: package.descriptor.publishedQuestionCount,
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects wrong package competency', () {
      final package = _package(
        envelopeOverrides: <String, dynamic>{'competencyId': 'd01_c02'},
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate question IDs', () {
      final duplicate = _questionJson(id: 101);
      final package = _package(
        questions: <Map<String, dynamic>>[duplicate, duplicate],
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects non-published questions', () {
      final package = _package(
        questions: <Map<String, dynamic>>[
          <String, dynamic>{..._questionJson(id: 101), 'status': 'validated'},
        ],
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects a question with other than four options', () {
      final package = _package(
        questions: <Map<String, dynamic>>[
          <String, dynamic>{
            ..._questionJson(id: 101),
            'options': <String>['A', 'B', 'C'],
          },
        ],
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects a correct answer outside 0-3', () {
      final package = _package(
        questions: <Map<String, dynamic>>[
          <String, dynamic>{..._questionJson(id: 101), 'correctAnswer': 4},
        ],
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects catalogue count mismatch', () {
      final package = _package();
      final descriptor = PublishedQuestionPackageDescriptor(
        competencyId: package.descriptor.competencyId,
        version: package.descriptor.version,
        checksumSha256: package.descriptor.checksumSha256,
        compressedBytes: package.descriptor.compressedBytes,
        publishedQuestionCount: 99,
      );

      expect(
        () => const QuestionPackageDecoder().decode(
          descriptor: descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });
  });
}

Map<String, dynamic> _descriptorJson() => <String, dynamic>{
  'competencyId': 'd01_c01',
  'questionVersion': 3,
  'questionChecksumSha256': _hex64('a'),
  'questionSizeBytes': 1234,
  'publishedQuestionCount': 2,
  'ultraHardCount': 1,
};

Map<String, dynamic> _resolutionJson({
  required bool current,
  String? signedUrl,
}) {
  return <String, dynamic>{
    ..._descriptorJson(),
    'current': current,
    if (signedUrl != null) 'signedUrl': signedUrl,
  };
}

({PublishedQuestionPackageDescriptor descriptor, List<int> bytes}) _package({
  List<Map<String, dynamic>>? questions,
  Map<String, dynamic> envelopeOverrides = const <String, dynamic>{},
}) {
  final questionPayloads =
      questions ??
      <Map<String, dynamic>>[_questionJson(id: 101), _questionJson(id: 102)];

  final envelope = <String, dynamic>{
    'schemaVersion': 1,
    'kind': 'questions',
    'competencyId': 'd01_c01',
    'sourceRecordMaxVersion': 2,
    'questionCount': questionPayloads.length,
    'questions': questionPayloads,
    ...envelopeOverrides,
  };

  final encoded = utf8.encode(jsonEncode(envelope));
  final compressed = GZipEncoder().encode(encoded);

  final descriptor = PublishedQuestionPackageDescriptor(
    competencyId: 'd01_c01',
    version: 3,
    checksumSha256: sha256.convert(compressed).toString(),
    compressedBytes: compressed.length,
    publishedQuestionCount: questionPayloads.length,
  );

  return (descriptor: descriptor, bytes: compressed);
}

Map<String, dynamic> _questionJson({required int id}) {
  return Question(
    id: id,
    domain: 1,
    competencyId: 'd01_c01',
    subtopicId: 'd01_c01_t01_s01',
    topicId: 'd01_c01_t01',
    quizId: 'd01_c01-v1_d01_c01_01_quiz',
    contentPackageId: 'content_d01_c01',
    question:
        'A safety professional evaluates a scenario and selects the best control.',
    options: const <String>[
      'Control the hazard at source.',
      'Add a warning sign only.',
      'Wait for another incident.',
      'Rely only on worker memory.',
    ],
    correctAnswer: 0,
    explanation: 'Source control provides the strongest practical protection.',
    reference: 'CSP11 reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: 'published',
    version: 2,
    tags: const <String>['risk-control'],
  ).toJson();
}

String _hex64(String character) {
  if (character.length != 1) {
    throw ArgumentError.value(character, 'character');
  }
  return List<String>.filled(64, character).join();
}
