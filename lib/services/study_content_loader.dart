import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/study_content.dart';

/// Loads CSP study content from the application's JSON assets.
///
/// The loader uses content_index.json as the source of truth for
/// domains, competencies, and their content file locations.
///
/// It contains no UI logic and no application state.
class StudyContentLoader {
  const StudyContentLoader();

  // ==========================================================
  // Content Index
  // ==========================================================

  /// Loads the master content index.
  ///
  /// The index contains the available domains and competencies.
  Future<Map<String, dynamic>> loadContentIndex() async {
    const assetPath = 'content/content_index.json';

    final jsonString = await rootBundle.loadString(assetPath);

    try {
      final decoded = json.decode(jsonString);

      if (decoded is! Map) {
        throw const FormatException(
          'Content index JSON must contain an object at the root.',
        );
      }

      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'Unable to parse content index: $assetPath\n$error',
      );
    }
  }

  // ==========================================================
  // Domains
  // ==========================================================

  /// Returns all domains defined in the content index.
  Future<List<Map<String, dynamic>>> loadDomains() async {
    final index = await loadContentIndex();

    final domains = index['domains'];

    if (domains is! List) {
      return <Map<String, dynamic>>[];
    }

    return domains
        .whereType<Map>()
        .map(
          (domain) => Map<String, dynamic>.from(domain),
        )
        .toList();
  }

  /// Finds a domain by its unique ID.
  ///
  /// Returns null if the domain does not exist.
  Future<Map<String, dynamic>?> loadDomain(
    String domainId,
  ) async {
    final domains = await loadDomains();

    for (final domain in domains) {
      if (domain['id']?.toString() == domainId) {
        return domain;
      }
    }

    return null;
  }

  // ==========================================================
  // Competencies
  // ==========================================================

  /// Returns all competencies belonging to a domain.
  Future<List<Map<String, dynamic>>> loadCompetencies(
    String domainId,
  ) async {
    final domain = await loadDomain(domainId);

    if (domain == null) {
      return <Map<String, dynamic>>[];
    }

    final competencies = domain['competencies'];

    if (competencies is! List) {
      return <Map<String, dynamic>>[];
    }

    return competencies
        .whereType<Map>()
        .map(
          (competency) => Map<String, dynamic>.from(competency),
        )
        .toList();
  }

  /// Finds a competency inside a domain.
  ///
  /// Returns null if the competency does not exist.
  Future<Map<String, dynamic>?> loadCompetencyIndexEntry(
    String domainId,
    String competencyId,
  ) async {
    final competencies = await loadCompetencies(domainId);

    for (final competency in competencies) {
      if (competency['id']?.toString() == competencyId) {
        return competency;
      }
    }

    return null;
  }

  // ==========================================================
  // Study Content
  // ==========================================================

  /// Loads a competency's actual study content.
  ///
  /// The location of the JSON file is obtained from content_index.json.
  Future<StudyContent> loadStudyContent({
    required String domainId,
    required String competencyId,
  }) async {
    final competency = await loadCompetencyIndexEntry(
      domainId,
      competencyId,
    );

    if (competency == null) {
      throw StateError(
        'Competency "$competencyId" was not found in domain "$domainId".',
      );
    }

    final file = competency['file'];

    if (file == null || file.toString().trim().isEmpty) {
      throw StateError(
        'No content file is defined for competency "$competencyId".',
      );
    }

    return loadCompetencyFile(file.toString());
  }

  /// Loads a study-content JSON file directly.
  ///
  /// This method is kept separate from the index-based loading so that
  /// the file-reading responsibility remains simple and reusable.
  Future<StudyContent> loadCompetencyFile(
    String assetPath,
  ) async {
    final jsonString = await rootBundle.loadString(assetPath);

    try {
      final decoded = json.decode(jsonString);

      if (decoded is! Map) {
        throw const FormatException(
          'Study content JSON must contain an object at the root.',
        );
      }

      return StudyContent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException(
        'Unable to parse study content: $assetPath\n$error',
      );
    }
  }
}