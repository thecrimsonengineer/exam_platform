import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_batch2_release_integration.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_firestore_repositories.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_deployment_acceptance.dart';
import 'package:exam_platform/features/lab/lab_production_release_operator.dart';
import 'package:exam_platform/features/lab/lab_published_payload_chunks.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected JSON object at ' + path + '.');
  }
  return decoded.cast<String, Object?>();
}

class _FileBatch2PopulationSource implements LabProductionPopulationSource {
  @override
  Future<LabScenarioPopulationManifest> loadManifest() async {
    return LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population_batch2/manifest.json'),
    );
  }

  @override
  Future<List<LabProductionPopulationSeedCandidate>> loadCandidates(
    LabScenarioPopulationManifest manifest,
  ) async {
    return manifest.entries
        .map(
          (entry) => LabProductionPopulationSeedCandidate(
            entryId: entry.entryId,
            technicalRoot: _readObject(entry.technicalLabPath),
            dqg300Evidence: const LabDqg300EvidenceCodec().decode(
              File(entry.dqg300EvidencePath).readAsStringSync(),
            ),
            presentationPackage: LabLearnerPresentationPackage.fromJson(
              _readObject(entry.learnerPresentationPath),
            ),
          ),
        )
        .toList(growable: false);
  }
}

Map<String, Object?> _encodePresentation(
  LabLearnerPresentationPackage package,
) {
  final overview = package.presentation;
  return <String, Object?>{
    'schemaVersion': package.schemaVersion,
    'labId': package.labId,
    'versionId': package.versionId,
    'presentation': <String, Object?>{
      'summary': overview.summary,
      'estimatedTime': overview.estimatedTime,
      'decisionCountLabel': overview.decisionCountLabel,
      'role': overview.role,
      'situation': overview.situation,
      'objective': overview.objective,
      'peopleInvolved': overview.peopleInvolved,
      'knownFacts': overview.knownFacts,
      'focusTags': overview.focusTags,
    },
    'evidencePresentation': <String, Object?>{
      for (final item in package.evidencePresentation.entries)
        item.key: <String, Object?>{
          'title': item.value.title,
          'summary': item.value.summary,
          'details': item.value.details,
        },
    },
    'decisionPresentation': <String, Object?>{
      for (final item in package.decisionPresentation.entries)
        item.key: <String, Object?>{'title': item.value.title},
    },
    'consequencePresentation': <String, Object?>{
      for (final item in package.consequencePresentation.entries)
        item.key: <String, Object?>{
          'observable': item.value.observable,
          'guidedInsight': item.value.guidedInsight,
        },
    },
    'endingPresentation': <String, Object?>{
      for (final item in package.endingPresentation.entries)
        item.key: <String, Object?>{
          'title': item.value.title,
          'narrative': item.value.narrative,
          'keyTurningPoint': item.value.keyTurningPoint,
        },
    },
  };
}

Map<String, Object?> _catalogueFields(
  LabLearnerCatalogueEntry entry, {
  required String releaseId,
}) =>
    <String, Object?>{
      'releaseId': releaseId,
      'manifestEntryId': entry.manifestEntryId,
      'labId': entry.labId,
      'versionId': entry.versionId,
      'title': entry.title,
      'summary': entry.summary,
      'focusTags': entry.focusTags,
      'estimatedTime': entry.estimatedTime,
      'decisionCountLabel': entry.decisionCountLabel,
      'decisionCount': entry.decisionCount,
      'supportedModes': entry.supportedModes
          .map((mode) => mode.name.toUpperCase())
          .toList(growable: false),
      'presentation': _encodePresentation(entry.presentation),
    };

Map<String, Object?> _publishedParentFields(
  LabPublishedVersion version,
  LabPublishedPayloadBundle payload,
) =>
    <String, Object?>{
      'schemaVersion': kLabPublishedChunkedFirestoreSchemaVersion,
      'labId': version.labId,
      'versionId': version.versionId,
      'lifecycle': 'published',
      'publishedAt': version.publishedAt.toUtc().toIso8601String(),
      'reviewerId': version.reviewerId,
      'validationAuthority': version.validationAuthority,
      'snapshotFingerprint': version.snapshotFingerprint,
      'payloadSchemaVersion': kLabPublishedPayloadSchemaVersion,
      'payloadManifest': payload.manifestJson,
      'payloadChunkCount': payload.chunks.length,
    };

Map<String, Object?> _publishedChunkFields(
  String versionKey,
  LabPublishedPayloadChunk chunk,
) =>
    <String, Object?>{
      ...chunk.toJson(),
      'versionKey': versionKey,
    };

void main() {
  test('generate exact Batch 2 production release bundle', () async {
    final source = _FileBatch2PopulationSource();
    final manifest = await source.loadManifest();

    final published = InMemoryLabPublishedRepository();
    final staging = InMemoryLabBatch2CatalogueStagingRepository();
    final evidenceRepository = InMemoryLabBatch2ReleaseEvidenceRepository();
    final catalogue = InMemoryLabLearnerCatalogueRepository();

    final releaseOperator = LabBatch2ReleaseOperatorService(
      populationSource: source,
      publishedRepository: published,
      stagingRepository: staging,
      evidenceRepository: evidenceRepository,
      environmentId: kExpectedLabProductionEnvironmentId,
    );

    final evidence = await releaseOperator.executeRelease(
      executedBy: 'github_batch2_direct_release',
      confirmationPhrase: kBatch2ReleaseConfirmationPhrase,
      executedAt: DateTime.utc(2026, 9, 25, 9, 10),
    );

    final acceptanceRepository = InMemoryLabBatch2ReleaseAcceptanceRepository(
      stagingRepository: staging,
      catalogueRepository: catalogue,
    );
    final acceptanceService = LabBatch2AcceptanceService(
      releaseOperator: releaseOperator,
      populationSource: source,
      acceptanceRepository: acceptanceRepository,
    );

    final acceptance = await acceptanceService.acceptLiveRelease(
      acceptedBy: 'github_batch2_direct_release',
      confirmationPhrase: kBatch2AcceptanceConfirmationPhrase,
      acceptedAt: DateTime.utc(2026, 9, 25, 9, 15),
    );

    expect(manifest.entries, hasLength(10));
    expect(evidence.labCount, 10);
    expect(evidence.totalDecisionCount, 50);
    expect(acceptance.labCount, 10);
    expect(acceptance.totalDecisionCount, 50);
    expect(await catalogue.listAvailable(), hasLength(10));

    final publishedParents = <Map<String, Object?>>[];
    final publishedChunks = <Map<String, Object?>>[];
    final stagingDocs = <Map<String, Object?>>[];
    final learnerDocs = <Map<String, Object?>>[];
    const payloadCodec = LabPublishedPayloadChunkCodec();

    for (final entry in manifest.entries) {
      final version = await published.load(entry.labId, entry.versionId);
      final staged = await staging.load(
        kBatch2ReleaseId,
        entry.labId,
        entry.versionId,
      );
      final learner = await catalogue.load(entry.labId, entry.versionId);

      expect(version, isNotNull);
      expect(staged, isNotNull);
      expect(learner, isNotNull);

      final versionKey = entry.labId + '__' + entry.versionId;
      final payload = payloadCodec.encode(<String, String>{
        'publishedJson': version!.publishedJson,
        'qualityEvidenceJson': version.qualityEvidenceJson!,
        'exhaustiveRouteEvidenceJson': version.exhaustiveRouteEvidenceJson!,
        'publishEvidenceJson': version.publishEvidenceJson!,
      });

      expect(payload.chunks, isNotEmpty);
      expect(
        payload.chunks.length,
        lessThanOrEqualTo(kLabPublishedPayloadMaxChunksPerVersion),
      );

      publishedParents.add(<String, Object?>{
        'id': versionKey,
        'data': _publishedParentFields(version, payload),
      });
      for (final chunk in payload.chunks) {
        final data = _publishedChunkFields(versionKey, chunk);
        expect(
          utf8.encode(jsonEncode(data)).length,
          lessThan(800 * 1024),
          reason: 'Chunk document must remain safely below Firestore 1 MiB.',
        );
        publishedChunks.add(<String, Object?>{
          'parentId': versionKey,
          'id': chunk.documentId,
          'data': data,
        });
      }

      stagingDocs.add(<String, Object?>{
        'id':
            kBatch2ReleaseId +
            '__' +
            entry.labId +
            '__' +
            entry.versionId,
        'data': <String, Object?>{
          'schemaVersion': kBatch2StagingSchemaVersion,
          ..._catalogueFields(staged!.entry, releaseId: kBatch2ReleaseId),
        },
      });

      learnerDocs.add(<String, Object?>{
        'id': entry.labId + '__' + entry.versionId,
        'data': <String, Object?>{
          'schemaVersion': kLabLearnerCatalogueFirestoreSchemaVersion,
          'available': true,
          ..._catalogueFields(learner!, releaseId: kBatch2ReleaseId),
        },
      });
    }

    final bundle = <String, Object?>{
      'schemaVersion': 'csp11.lab.batch2.direct_release_bundle.v2',
      'projectId': 'csp11-exam-platform',
      'releaseId': kBatch2ReleaseId,
      'environmentId': kExpectedLabProductionEnvironmentId,
      'manifestId': evidence.manifestId,
      'manifestFingerprint': evidence.manifestFingerprint,
      'labCount': evidence.labCount,
      'totalDecisionCount': evidence.totalDecisionCount,
      'publishedParents': publishedParents,
      'publishedChunks': publishedChunks,
      'publishedChunkCount': publishedChunks.length,
      'staging': stagingDocs,
      'q16Evidence': <String, Object?>{
        'id': kBatch2ReleaseId,
        'data': evidence.toJson(),
      },
      'q16State': <String, Object?>{
        'id': kBatch2ReleaseId,
        'data': <String, Object?>{
          'schemaVersion': 'csp11.lab.production_extension_release_state.v1',
          'releaseId': evidence.releaseId,
          'manifestId': evidence.manifestId,
          'released': true,
          'labCount': evidence.labCount,
          'totalDecisionCount': evidence.totalDecisionCount,
          'evidenceFingerprint': evidence.evidenceFingerprint,
        },
      },
      'q17Acceptance': <String, Object?>{
        'id': kBatch2ReleaseId,
        'data': acceptance.toJson(),
      },
      'q17Visibility': <String, Object?>{
        'id': kBatch2ReleaseId,
        'data': <String, Object?>{
          'schemaVersion': kBatch2LearnerVisibilitySchemaVersion,
          'releaseId': acceptance.releaseId,
          'accepted': true,
          'evidenceFingerprint': acceptance.evidenceFingerprint,
          'acceptanceFingerprint': acceptance.acceptanceFingerprint,
        },
      },
      'learnerCatalogue': learnerDocs,
    };

    final output = File('build/batch2_direct_release/release_bundle.json');
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(bundle) + '\n',
    );

    expect(output.existsSync(), isTrue);
  });
}
