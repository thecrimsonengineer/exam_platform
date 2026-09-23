import 'dart:convert';

import 'package:crypto/crypto.dart';

class MicroFactPairComparison {
  const MicroFactPairComparison({
    required this.pairKey,
    required this.exactDuplicateReasons,
    required this.signals,
    required this.displayJaccard,
    required this.shortJaccard,
    required this.conceptJaccard,
  });

  final String pairKey;
  final Set<String> exactDuplicateReasons;
  final Set<String> signals;
  final double displayJaccard;
  final double shortJaccard;
  final double conceptJaccard;

  bool get hasExactDuplicate => exactDuplicateReasons.isNotEmpty;
  bool get requiresAdjudication => signals.isNotEmpty;
}

class MicroFactCorpusComparison {
  static const Set<String> _negativePolarityTokens = {
    'no',
    'not',
    'never',
    'without',
    'cannot',
    'prohibited',
    'prohibits',
    'forbidden',
  };

  const MicroFactCorpusComparison();

  MicroFactPairComparison compare({
    required Map<String, dynamic> left,
    required Map<String, dynamic> right,
    required Map<String, dynamic> policy,
  }) {
    final normalization = Map<String, dynamic>.from(
      policy['normalization'] as Map,
    );
    final duplicateRules = Map<String, dynamic>.from(
      policy['duplicateRules'] as Map,
    );
    final contradictionRules = Map<String, dynamic>.from(
      policy['contradictionRules'] as Map,
    );

    final leftDisplay = _displayText(left);
    final rightDisplay = _displayText(right);
    final leftShort = _shortVariant(left);
    final rightShort = _shortVariant(right);

    final leftDisplayTokens = normalizedTokens(leftDisplay, normalization);
    final rightDisplayTokens = normalizedTokens(rightDisplay, normalization);
    final leftShortTokens = leftShort == null
        ? const <String>[]
        : normalizedTokens(leftShort, normalization);
    final rightShortTokens = rightShort == null
        ? const <String>[]
        : normalizedTokens(rightShort, normalization);

    final displayJaccard = jaccard(
      leftDisplayTokens.toSet(),
      rightDisplayTokens.toSet(),
    );
    final shortJaccard = leftShortTokens.isEmpty || rightShortTokens.isEmpty
        ? 0.0
        : jaccard(leftShortTokens.toSet(), rightShortTokens.toSet());

    final leftConcepts = _conceptIds(left);
    final rightConcepts = _conceptIds(right);
    final conceptJaccard = jaccard(leftConcepts, rightConcepts);

    final exactReasons = <String>{};
    final signals = <String>{};

    final normalizedLeftDisplay = leftDisplayTokens.join(' ');
    final normalizedRightDisplay = rightDisplayTokens.join(' ');
    if (normalizedLeftDisplay.isNotEmpty &&
        normalizedLeftDisplay == normalizedRightDisplay) {
      exactReasons.add('exact_normalized_display');
    }

    if (leftShortTokens.isNotEmpty &&
        rightShortTokens.isNotEmpty &&
        leftShortTokens.join(' ') == rightShortTokens.join(' ')) {
      exactReasons.add('exact_normalized_short');
    }

    if (sha256Text(leftDisplay) == sha256Text(rightDisplay)) {
      exactReasons.add('exact_display_hash');
    }

    final minimumConceptJaccard =
        (duplicateRules['minimumConceptJaccardForNearDuplicate'] as num)
            .toDouble();

    if (conceptJaccard >= minimumConceptJaccard &&
        (displayJaccard >=
                (duplicateRules['nearDuplicateDisplayJaccardThreshold'] as num)
                    .toDouble() ||
            shortJaccard >=
                (duplicateRules['nearDuplicateShortJaccardThreshold'] as num)
                    .toDouble())) {
      signals.add('near_duplicate');
    }

    final exactConceptSet =
        leftConcepts.length == rightConcepts.length &&
        leftConcepts.containsAll(rightConcepts);
    if (exactConceptSet &&
        left['category'] == right['category'] &&
        displayJaccard >=
            (duplicateRules['conceptAssistedDisplayJaccardThreshold'] as num)
                .toDouble()) {
      signals.add('concept_assisted_duplicate');
    }

    if (_sameSourceLocator(left, right) &&
        conceptJaccard >= minimumConceptJaccard &&
        displayJaccard >=
            (duplicateRules['sameSourceLocatorConceptAssistedThreshold'] as num)
                .toDouble()) {
      signals.add('same_source_locator_overlap');
    }

    if (conceptJaccard >=
            (contradictionRules['polarityConflictMinConceptJaccard'] as num)
                .toDouble() &&
        displayJaccard >=
            (contradictionRules['polarityConflictMinTextJaccard'] as num)
                .toDouble() &&
        _hasNegativePolarity(leftDisplayTokens) !=
            _hasNegativePolarity(rightDisplayTokens)) {
      signals.add('polarity_conflict');
    }

    final leftClaim = Map<String, dynamic>.from(left['claim'] as Map);
    final rightClaim = Map<String, dynamic>.from(right['claim'] as Map);

    if (leftClaim['legalStatus'] != rightClaim['legalStatus'] &&
        conceptJaccard >=
            (contradictionRules['legalStatusConflictMinConceptJaccard'] as num)
                .toDouble() &&
        displayJaccard >=
            (contradictionRules['legalStatusConflictMinTextJaccard'] as num)
                .toDouble() &&
        _legalJurisdictionComparable(leftClaim, rightClaim)) {
      signals.add('legal_status_conflict');
    }

    if (leftClaim['numericalClaim'] == true &&
        rightClaim['numericalClaim'] == true &&
        conceptJaccard >=
            (contradictionRules['numericalConflictMinConceptJaccard'] as num)
                .toDouble() &&
        displayJaccard >=
            (contradictionRules['numericalConflictMinTextJaccard'] as num)
                .toDouble() &&
        _numericalJurisdictionComparable(leftClaim, rightClaim) &&
        _hasConflictingNumericSignature(left, right)) {
      signals.add('numerical_conflict');
    }

    if (_sameSourceLocator(left, right) && _editionDrift(left, right)) {
      signals.add('edition_drift');
    }

    return MicroFactPairComparison(
      pairKey: pairKey(left, right),
      exactDuplicateReasons: Set.unmodifiable(exactReasons),
      signals: Set.unmodifiable(signals),
      displayJaccard: displayJaccard,
      shortJaccard: shortJaccard,
      conceptJaccard: conceptJaccard,
    );
  }

  static List<String> normalizedTokens(
    String value,
    Map<String, dynamic> normalization,
  ) {
    var input = value;
    if (normalization['lowercase'] == true) {
      input = input.toLowerCase();
    }

    final stopWords = (normalization['stopWords'] as List)
        .whereType<String>()
        .map((value) => value.toLowerCase())
        .toSet();
    final protected = (normalization['protectedTokens'] as List)
        .whereType<String>()
        .map((value) => value.toLowerCase())
        .toSet();

    final tokens = RegExp(r'[a-z0-9%³]+(?:/[a-z0-9%³]+)?')
        .allMatches(input)
        .map((match) => match.group(0)!)
        .where(
          (token) => protected.contains(token) || !stopWords.contains(token),
        )
        .toList(growable: false);

    return tokens;
  }

  static double jaccard(Set<String> left, Set<String> right) {
    if (left.isEmpty && right.isEmpty) return 1.0;
    if (left.isEmpty || right.isEmpty) return 0.0;

    final intersection = left.intersection(right).length;
    final union = left.union(right).length;
    return intersection / union;
  }

  static String pairKey(Map<String, dynamic> left, Map<String, dynamic> right) {
    final leftKey = factVersionKey(left);
    final rightKey = factVersionKey(right);
    final ordered = [leftKey, rightKey]..sort();
    return ordered.join('||');
  }

  static String factVersionKey(Map<String, dynamic> fact) =>
      (fact['microFactId'] as String) +
      '@' +
      (fact['contentVersion'] as int).toString();

  static String comparisonFingerprint(Map<String, dynamic> fact) {
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    final claim = Map<String, dynamic>.from(fact['claim'] as Map);

    final concepts =
        (curriculum['conceptIds'] as List).whereType<String>().toList()..sort();

    final payload = <String, dynamic>{
      'microFactId': fact['microFactId'],
      'contentVersion': fact['contentVersion'],
      'category': fact['category'],
      'displayText': display['displayText'],
      'shortVariant': display['shortVariant'],
      'conceptIds': concepts,
      'sourceRegistryId': provenance['sourceRegistryId'],
      'sourceClass': provenance['sourceClass'],
      'sourceLocator': provenance['sourceLocator'],
      'editionOrRevision': provenance['editionOrRevision'],
      'legalStatus': claim['legalStatus'],
      'jurisdiction': claim['jurisdiction'],
      'numericalClaim': claim['numericalClaim'],
    };

    return sha256Text(jsonEncode(payload));
  }

  static String sha256Text(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static Map<String, Set<String>> numericSignatures(Map<String, dynamic> fact) {
    final text = [
      _displayText(fact),
      _shortVariant(fact) ?? '',
    ].join(' ').toLowerCase();

    final result = <String, Set<String>>{};
    final pattern = RegExp(
      r'\b(\d+(?:\.\d+)?)\s*'
      r'(%|ppm|ppb|mg\s*/\s*m(?:3|³)|dba|db|°?\s*c|°?\s*f|'
      r'kv|volts?|v|psi|feet|foot|ft|meters?|metres?|m|'
      r'seconds?|minutes?|hours?|days?)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      final value = _normalizeNumericValue(match.group(1)!);
      final unit = _normalizeUnit(match.group(2)!);
      result.putIfAbsent(unit, () => <String>{}).add(value);
    }

    return result;
  }

  static bool _hasConflictingNumericSignature(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftValues = numericSignatures(left);
    final rightValues = numericSignatures(right);

    final commonUnits = leftValues.keys.toSet().intersection(
      rightValues.keys.toSet(),
    );
    for (final unit in commonUnits) {
      if (!_setEquals(leftValues[unit]!, rightValues[unit]!)) {
        return true;
      }
    }
    return false;
  }

  static bool _sameSourceLocator(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftSource = Map<String, dynamic>.from(left['provenance'] as Map);
    final rightSource = Map<String, dynamic>.from(right['provenance'] as Map);
    return leftSource['sourceRegistryId'] == rightSource['sourceRegistryId'] &&
        _normalizedNullable(leftSource['sourceLocator']) ==
            _normalizedNullable(rightSource['sourceLocator']);
  }

  static bool _editionDrift(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftSource = Map<String, dynamic>.from(left['provenance'] as Map);
    final rightSource = Map<String, dynamic>.from(right['provenance'] as Map);
    final leftEdition = _normalizedNullable(leftSource['editionOrRevision']);
    final rightEdition = _normalizedNullable(rightSource['editionOrRevision']);

    return leftEdition != null &&
        rightEdition != null &&
        leftEdition != rightEdition;
  }

  static bool _legalJurisdictionComparable(
    Map<String, dynamic> leftClaim,
    Map<String, dynamic> rightClaim,
  ) {
    final leftJurisdiction = _normalizedNullable(leftClaim['jurisdiction']);
    final rightJurisdiction = _normalizedNullable(rightClaim['jurisdiction']);
    final bindingPresent =
        leftClaim['legalStatus'] == 'binding_requirement' ||
        rightClaim['legalStatus'] == 'binding_requirement';

    if (!bindingPresent) return true;
    if (leftJurisdiction == null || rightJurisdiction == null) return true;
    return leftJurisdiction == rightJurisdiction;
  }

  static bool _numericalJurisdictionComparable(
    Map<String, dynamic> leftClaim,
    Map<String, dynamic> rightClaim,
  ) {
    final leftJurisdiction = _normalizedNullable(leftClaim['jurisdiction']);
    final rightJurisdiction = _normalizedNullable(rightClaim['jurisdiction']);
    if (leftJurisdiction == null || rightJurisdiction == null) return true;
    return leftJurisdiction == rightJurisdiction;
  }

  static bool _hasNegativePolarity(List<String> tokens) =>
      tokens.any(_negativePolarityTokens.contains);

  static Set<String> _conceptIds(Map<String, dynamic> fact) {
    final curriculum = Map<String, dynamic>.from(fact['curriculum'] as Map);
    return (curriculum['conceptIds'] as List).whereType<String>().toSet();
  }

  static String _displayText(Map<String, dynamic> fact) {
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    return display['displayText'] as String;
  }

  static String? _shortVariant(Map<String, dynamic> fact) {
    final display = Map<String, dynamic>.from(fact['display'] as Map);
    return display['shortVariant'] as String?;
  }

  static String _normalizeNumericValue(String value) {
    final parsed = double.parse(value);
    if (parsed == parsed.roundToDouble()) {
      return parsed.toInt().toString();
    }
    return parsed.toString();
  }

  static String _normalizeUnit(String unit) {
    final normalized = unit
        .toLowerCase()
        .replaceAll('°', '')
        .replaceAll(RegExp(r'\s+'), '');

    if (normalized == 'volt' || normalized == 'volts') return 'v';
    if (normalized == 'feet' || normalized == 'foot') return 'ft';
    if (normalized == 'meter' ||
        normalized == 'meters' ||
        normalized == 'metre' ||
        normalized == 'metres') {
      return 'm';
    }
    if (normalized == 'second' || normalized == 'seconds') return 'seconds';
    if (normalized == 'minute' || normalized == 'minutes') return 'minutes';
    if (normalized == 'hour' || normalized == 'hours') return 'hours';
    if (normalized == 'day' || normalized == 'days') return 'days';
    return normalized;
  }

  static String? _normalizedNullable(dynamic value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  static bool _setEquals(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);
}
