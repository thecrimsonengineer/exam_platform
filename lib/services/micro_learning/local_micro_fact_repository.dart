import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/micro_learning/micro_fact.dart';
import 'micro_fact_schema_validator.dart';

typedef MicroFactAssetTextLoader = Future<String> Function(String assetPath);

class LocalMicroFactRepositorySnapshot {
  const LocalMicroFactRepositorySnapshot({
    required this.bundleValid,
    required this.bundleId,
    required this.bundleVersion,
    required this.bundleFactCount,
    required this.eligibleFacts,
    required this.staleFactCount,
    required this.diagnostics,
  });

  LocalMicroFactRepositorySnapshot.failed(String diagnostic)
    : bundleValid = false,
      bundleId = null,
      bundleVersion = null,
      bundleFactCount = 0,
      eligibleFacts = const <MicroFact>[],
      staleFactCount = 0,
      diagnostics = List<String>.unmodifiable([diagnostic]);

  final bool bundleValid;
  final String? bundleId;
  final int? bundleVersion;
  final int bundleFactCount;
  final List<MicroFact> eligibleFacts;
  final int staleFactCount;
  final List<String> diagnostics;

  bool get hasEligibleFacts => eligibleFacts.isNotEmpty;
}

class LocalMicroFactRepository {
  LocalMicroFactRepository({MicroFactAssetTextLoader? assetLoader})
    : _assetLoader =
          assetLoader ?? ((path) => rootBundle.loadString(path));

  static const String bundleAssetPath =
      'content/micro_learning/ml10_runtime_bundle_v1.json';
  static const String requiredBundleId = 'csp11_micro_learning_runtime_v1';
  static const int requiredBundleVersion = 1;
  static const int requiredFactCount = 120;
  static const String requiredSourcePublicationSha =
      'b9915db98fc644edaee8ed51e707dd24b120104f';
  static const int maxSourceVerificationAgeDays = 365;

  final MicroFactAssetTextLoader _assetLoader;

  Future<LocalMicroFactRepositorySnapshot> load({DateTime? now}) async {
    final today = _dateOnly(now ?? DateTime.now());

    try {
      final raw = await _assetLoader(bundleAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return LocalMicroFactRepositorySnapshot.failed(
          'ML10_BUNDLE_ROOT_INVALID',
        );
      }

      final bundle = Map<String, dynamic>.from(decoded);
      final structuralIssues = _validateBundleHeader(bundle);
      if (structuralIssues.isNotEmpty) {
        return LocalMicroFactRepositorySnapshot(
          bundleValid: false,
          bundleId: bundle['bundleId'] as String?,
          bundleVersion: bundle['bundleVersion'] as int?,
          bundleFactCount: 0,
          eligibleFacts: const <MicroFact>[],
          staleFactCount: 0,
          diagnostics: List<String>.unmodifiable(structuralIssues),
        );
      }

      final rawFacts = bundle['facts'] as List;
      final facts = <MicroFact>[];
      final ids = <String>{};
      final diagnostics = <String>[];
      var staleCount = 0;

      for (var index = 0; index < rawFacts.length; index++) {
        final rawFact = rawFacts[index];
        if (rawFact is! Map) {
          diagnostics.add('ML10_FACT_OBJECT_INVALID:$index');
          continue;
        }

        final factMap = Map<String, dynamic>.from(rawFact);
        final schemaResult = MicroFactSchemaValidator().validateMap(factMap);
        if (!schemaResult.isValid) {
          diagnostics.add(
            'ML10_FACT_SCHEMA_INVALID:${factMap['microFactId'] ?? index}',
          );
          continue;
        }

        final fact = MicroFact.fromValidatedJson(factMap);
        if (!ids.add(fact.microFactId)) {
          diagnostics.add('ML10_FACT_DUPLICATE:${fact.microFactId}');
          continue;
        }

        if (fact.status != 'published' || !fact.runtime.startupEligible) {
          diagnostics.add('ML10_FACT_NOT_PUBLISHED:${fact.microFactId}');
          continue;
        }

        if (!_reviewPasses(fact.review)) {
          diagnostics.add('ML10_FACT_REVIEW_NOT_PASS:${fact.microFactId}');
          continue;
        }

        if (!_isCurrent(fact, today)) {
          staleCount++;
          continue;
        }

        facts.add(fact);
      }

      final hardIssues = diagnostics.where(
        (entry) =>
            entry.startsWith('ML10_FACT_OBJECT_INVALID') ||
            entry.startsWith('ML10_FACT_SCHEMA_INVALID') ||
            entry.startsWith('ML10_FACT_DUPLICATE') ||
            entry.startsWith('ML10_FACT_NOT_PUBLISHED') ||
            entry.startsWith('ML10_FACT_REVIEW_NOT_PASS'),
      );

      if (hardIssues.isNotEmpty || ids.length != requiredFactCount) {
        return LocalMicroFactRepositorySnapshot(
          bundleValid: false,
          bundleId: bundle['bundleId'] as String,
          bundleVersion: bundle['bundleVersion'] as int,
          bundleFactCount: rawFacts.length,
          eligibleFacts: const <MicroFact>[],
          staleFactCount: staleCount,
          diagnostics: List<String>.unmodifiable([
            ...diagnostics,
            if (ids.length != requiredFactCount)
              'ML10_FACT_ID_COVERAGE_INVALID:${ids.length}',
          ]),
        );
      }

      facts.sort((a, b) => a.microFactId.compareTo(b.microFactId));
      return LocalMicroFactRepositorySnapshot(
        bundleValid: true,
        bundleId: bundle['bundleId'] as String,
        bundleVersion: bundle['bundleVersion'] as int,
        bundleFactCount: rawFacts.length,
        eligibleFacts: List<MicroFact>.unmodifiable(facts),
        staleFactCount: staleCount,
        diagnostics: List<String>.unmodifiable(diagnostics),
      );
    } catch (_) {
      return LocalMicroFactRepositorySnapshot.failed(
        'ML10_BUNDLE_LOAD_FAILED',
      );
    }
  }

  List<String> _validateBundleHeader(Map<String, dynamic> bundle) {
    final issues = <String>[];

    if (bundle['schemaVersion'] != 1) {
      issues.add('ML10_BUNDLE_SCHEMA_VERSION');
    }
    if (bundle['bundleId'] != requiredBundleId) {
      issues.add('ML10_BUNDLE_ID');
    }
    if (bundle['bundleVersion'] != requiredBundleVersion) {
      issues.add('ML10_BUNDLE_VERSION');
    }
    if (bundle['sourcePublicationSha'] != requiredSourcePublicationSha) {
      issues.add('ML10_BUNDLE_SOURCE_SHA');
    }
    if (bundle['factCount'] != requiredFactCount) {
      issues.add('ML10_BUNDLE_FACT_COUNT');
    }
    final facts = bundle['facts'];
    if (facts is! List || facts.length != requiredFactCount) {
      issues.add('ML10_BUNDLE_FACTS');
    }

    return issues;
  }

  bool _reviewPasses(MicroFactReview review) {
    return review.technicalStatus == 'pass' &&
        review.sourceStatus == 'pass' &&
        review.pedagogyStatus == 'pass' &&
        review.copyrightStatus == 'pass' &&
        review.uiStatus == 'pass' &&
        review.humanTechnicalStatus == 'pass' &&
        review.reviewedAt != null &&
        review.nextReviewDueAt != null;
  }

  bool _isCurrent(MicroFact fact, DateTime today) {
    final reviewedAt = _parseStrictDate(fact.review.reviewedAt);
    final nextReviewDueAt = _parseStrictDate(fact.review.nextReviewDueAt);
    final sourceVerifiedAt = _parseStrictDate(
      fact.provenance.sourceVerifiedAt,
    );

    if (reviewedAt == null ||
        nextReviewDueAt == null ||
        sourceVerifiedAt == null) {
      return false;
    }

    if (reviewedAt.isAfter(today) || sourceVerifiedAt.isAfter(today)) {
      return false;
    }

    if (nextReviewDueAt.isBefore(today)) {
      return false;
    }

    if (today.difference(sourceVerifiedAt).inDays >
        maxSourceVerificationAgeDays) {
      return false;
    }

    return true;
  }

  DateTime? _parseStrictDate(String? value) {
    if (value == null ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }

    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';

    return normalized == value ? _dateOnly(parsed) : null;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
