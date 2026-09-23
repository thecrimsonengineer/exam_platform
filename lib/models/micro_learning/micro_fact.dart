class MicroFact {
  const MicroFact({
    required this.schemaVersion,
    required this.microFactId,
    required this.contentVersion,
    required this.status,
    required this.category,
    required this.display,
    required this.curriculum,
    required this.provenance,
    required this.claim,
    required this.assessment,
    required this.review,
    required this.runtime,
    required this.supersession,
    required this.tags,
  });

  final int schemaVersion;
  final String microFactId;
  final int contentVersion;
  final String status;
  final String category;
  final MicroFactDisplay display;
  final MicroFactCurriculum curriculum;
  final MicroFactProvenance provenance;
  final MicroFactClaim claim;
  final MicroFactAssessment assessment;
  final MicroFactReview review;
  final MicroFactRuntime runtime;
  final MicroFactSupersession supersession;
  final List<String> tags;

  factory MicroFact.fromValidatedJson(Map<String, dynamic> json) {
    return MicroFact(
      schemaVersion: json['schemaVersion'] as int,
      microFactId: json['microFactId'] as String,
      contentVersion: json['contentVersion'] as int,
      status: json['status'] as String,
      category: json['category'] as String,
      display: MicroFactDisplay.fromJson(
        Map<String, dynamic>.from(json['display'] as Map),
      ),
      curriculum: MicroFactCurriculum.fromJson(
        Map<String, dynamic>.from(json['curriculum'] as Map),
      ),
      provenance: MicroFactProvenance.fromJson(
        Map<String, dynamic>.from(json['provenance'] as Map),
      ),
      claim: MicroFactClaim.fromJson(
        Map<String, dynamic>.from(json['claim'] as Map),
      ),
      assessment: MicroFactAssessment.fromJson(
        Map<String, dynamic>.from(json['assessment'] as Map),
      ),
      review: MicroFactReview.fromJson(
        Map<String, dynamic>.from(json['review'] as Map),
      ),
      runtime: MicroFactRuntime.fromJson(
        Map<String, dynamic>.from(json['runtime'] as Map),
      ),
      supersession: MicroFactSupersession.fromJson(
        Map<String, dynamic>.from(json['supersession'] as Map),
      ),
      tags: List<String>.unmodifiable((json['tags'] as List).cast<String>()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'microFactId': microFactId,
      'contentVersion': contentVersion,
      'status': status,
      'category': category,
      'display': display.toJson(),
      'curriculum': curriculum.toJson(),
      'provenance': provenance.toJson(),
      'claim': claim.toJson(),
      'assessment': assessment.toJson(),
      'review': review.toJson(),
      'runtime': runtime.toJson(),
      'supersession': supersession.toJson(),
      'tags': tags,
    };
  }
}

class MicroFactDisplay {
  const MicroFactDisplay({
    required this.displayText,
    required this.shortVariant,
    required this.estimatedReadSeconds,
  });

  final String displayText;
  final String? shortVariant;
  final int estimatedReadSeconds;

  factory MicroFactDisplay.fromJson(Map<String, dynamic> json) {
    return MicroFactDisplay(
      displayText: json['displayText'] as String,
      shortVariant: json['shortVariant'] as String?,
      estimatedReadSeconds: json['estimatedReadSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayText': displayText,
    'shortVariant': shortVariant,
    'estimatedReadSeconds': estimatedReadSeconds,
  };
}

class MicroFactCurriculum {
  const MicroFactCurriculum({
    required this.scope,
    required this.domainId,
    required this.competencyId,
    required this.topicId,
    required this.subtopicId,
    required this.conceptIds,
  });

  final String scope;
  final String? domainId;
  final String? competencyId;
  final String? topicId;
  final String? subtopicId;
  final List<String> conceptIds;

  factory MicroFactCurriculum.fromJson(Map<String, dynamic> json) {
    return MicroFactCurriculum(
      scope: json['scope'] as String,
      domainId: json['domainId'] as String?,
      competencyId: json['competencyId'] as String?,
      topicId: json['topicId'] as String?,
      subtopicId: json['subtopicId'] as String?,
      conceptIds: List<String>.unmodifiable(
        (json['conceptIds'] as List).cast<String>(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'scope': scope,
    'domainId': domainId,
    'competencyId': competencyId,
    'topicId': topicId,
    'subtopicId': subtopicId,
    'conceptIds': conceptIds,
  };
}

class MicroFactProvenance {
  const MicroFactProvenance({
    required this.sourceRegistryId,
    required this.sourceClass,
    required this.sourceTitle,
    required this.officialUrl,
    required this.sourceLocator,
    required this.editionOrRevision,
    required this.sourceSection,
    required this.sourcePage,
    required this.sourcePublishedAt,
    required this.sourceVerifiedAt,
    required this.rightsTreatment,
  });

  final String sourceRegistryId;
  final String sourceClass;
  final String sourceTitle;
  final String officialUrl;
  final String sourceLocator;
  final String? editionOrRevision;
  final String? sourceSection;
  final String? sourcePage;
  final String? sourcePublishedAt;
  final String sourceVerifiedAt;
  final String rightsTreatment;

  factory MicroFactProvenance.fromJson(Map<String, dynamic> json) {
    return MicroFactProvenance(
      sourceRegistryId: json['sourceRegistryId'] as String,
      sourceClass: json['sourceClass'] as String,
      sourceTitle: json['sourceTitle'] as String,
      officialUrl: json['officialUrl'] as String,
      sourceLocator: json['sourceLocator'] as String,
      editionOrRevision: json['editionOrRevision'] as String?,
      sourceSection: json['sourceSection'] as String?,
      sourcePage: json['sourcePage'] as String?,
      sourcePublishedAt: json['sourcePublishedAt'] as String?,
      sourceVerifiedAt: json['sourceVerifiedAt'] as String,
      rightsTreatment: json['rightsTreatment'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'sourceRegistryId': sourceRegistryId,
    'sourceClass': sourceClass,
    'sourceTitle': sourceTitle,
    'officialUrl': officialUrl,
    'sourceLocator': sourceLocator,
    'editionOrRevision': editionOrRevision,
    'sourceSection': sourceSection,
    'sourcePage': sourcePage,
    'sourcePublishedAt': sourcePublishedAt,
    'sourceVerifiedAt': sourceVerifiedAt,
    'rightsTreatment': rightsTreatment,
  };
}

class MicroFactClaim {
  const MicroFactClaim({
    required this.legalStatus,
    required this.jurisdiction,
    required this.numericalClaim,
    required this.safetyCritical,
    required this.simplificationRisk,
  });

  final String legalStatus;
  final String? jurisdiction;
  final bool numericalClaim;
  final bool safetyCritical;
  final String simplificationRisk;

  factory MicroFactClaim.fromJson(Map<String, dynamic> json) {
    return MicroFactClaim(
      legalStatus: json['legalStatus'] as String,
      jurisdiction: json['jurisdiction'] as String?,
      numericalClaim: json['numericalClaim'] as bool,
      safetyCritical: json['safetyCritical'] as bool,
      simplificationRisk: json['simplificationRisk'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'legalStatus': legalStatus,
    'jurisdiction': jurisdiction,
    'numericalClaim': numericalClaim,
    'safetyCritical': safetyCritical,
    'simplificationRisk': simplificationRisk,
  };
}

class MicroFactAssessment {
  const MicroFactAssessment({
    required this.sensitivity,
    required this.linkedQuestionConcepts,
  });

  final String sensitivity;
  final List<String> linkedQuestionConcepts;

  factory MicroFactAssessment.fromJson(Map<String, dynamic> json) {
    return MicroFactAssessment(
      sensitivity: json['sensitivity'] as String,
      linkedQuestionConcepts: List<String>.unmodifiable(
        (json['linkedQuestionConcepts'] as List).cast<String>(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'sensitivity': sensitivity,
    'linkedQuestionConcepts': linkedQuestionConcepts,
  };
}

class MicroFactReview {
  const MicroFactReview({
    required this.technicalStatus,
    required this.sourceStatus,
    required this.pedagogyStatus,
    required this.copyrightStatus,
    required this.uiStatus,
    required this.humanTechnicalStatus,
    required this.reviewedAt,
    required this.nextReviewDueAt,
  });

  final String technicalStatus;
  final String sourceStatus;
  final String pedagogyStatus;
  final String copyrightStatus;
  final String uiStatus;
  final String humanTechnicalStatus;
  final String? reviewedAt;
  final String? nextReviewDueAt;

  factory MicroFactReview.fromJson(Map<String, dynamic> json) {
    return MicroFactReview(
      technicalStatus: json['technicalStatus'] as String,
      sourceStatus: json['sourceStatus'] as String,
      pedagogyStatus: json['pedagogyStatus'] as String,
      copyrightStatus: json['copyrightStatus'] as String,
      uiStatus: json['uiStatus'] as String,
      humanTechnicalStatus: json['humanTechnicalStatus'] as String,
      reviewedAt: json['reviewedAt'] as String?,
      nextReviewDueAt: json['nextReviewDueAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'technicalStatus': technicalStatus,
    'sourceStatus': sourceStatus,
    'pedagogyStatus': pedagogyStatus,
    'copyrightStatus': copyrightStatus,
    'uiStatus': uiStatus,
    'humanTechnicalStatus': humanTechnicalStatus,
    'reviewedAt': reviewedAt,
    'nextReviewDueAt': nextReviewDueAt,
  };
}

class MicroFactRuntime {
  const MicroFactRuntime({required this.startupEligible});

  final bool startupEligible;

  factory MicroFactRuntime.fromJson(Map<String, dynamic> json) {
    return MicroFactRuntime(startupEligible: json['startupEligible'] as bool);
  }

  Map<String, dynamic> toJson() => {'startupEligible': startupEligible};
}

class MicroFactSupersession {
  const MicroFactSupersession({
    required this.supersedesMicroFactId,
    required this.supersededByMicroFactId,
  });

  final String? supersedesMicroFactId;
  final String? supersededByMicroFactId;

  factory MicroFactSupersession.fromJson(Map<String, dynamic> json) {
    return MicroFactSupersession(
      supersedesMicroFactId: json['supersedesMicroFactId'] as String?,
      supersededByMicroFactId: json['supersededByMicroFactId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'supersedesMicroFactId': supersedesMicroFactId,
    'supersededByMicroFactId': supersededByMicroFactId,
  };
}
