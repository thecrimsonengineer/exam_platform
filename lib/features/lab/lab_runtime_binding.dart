import 'package:cloud_firestore/cloud_firestore.dart';

import 'lab_firestore_repositories.dart';
import 'lab_learner_catalogue.dart';
import 'lab_production_release_closure.dart';

class LabLearnerRuntimeBinding {
  const LabLearnerRuntimeBinding({
    required this.deliveryService,
    this.releaseEvidenceRepository,
    this.requiredReleaseId,
  });

  factory LabLearnerRuntimeBinding.firestore({FirebaseFirestore? firestore}) {
    final instance = firestore ?? FirebaseFirestore.instance;
    return LabLearnerRuntimeBinding(
      deliveryService: LabLearnerControlledDeliveryService(
        publishedRepository: FirestoreLabPublishedRepository(
          firestore: instance,
        ),
        catalogueRepository: FirestoreLabLearnerCatalogueRepository(
          firestore: instance,
        ),
      ),
    );
  }

  factory LabLearnerRuntimeBinding.firestoreProduction({
    FirebaseFirestore? firestore,
    String releaseId = kInitialLabProductionReleaseId,
  }) {
    final instance = firestore ?? FirebaseFirestore.instance;
    return LabLearnerRuntimeBinding(
      deliveryService: LabLearnerControlledDeliveryService(
        publishedRepository: FirestoreLabPublishedRepository(
          firestore: instance,
        ),
        catalogueRepository: FirestoreLabLearnerCatalogueRepository(
          firestore: instance,
        ),
      ),
      releaseEvidenceRepository:
          FirestoreLabProductionReleaseEvidenceRepository(
            firestore: instance,
          ),
      requiredReleaseId: releaseId,
    );
  }

  final LabLearnerControlledDeliveryService deliveryService;
  final LabProductionReleaseEvidenceRepository? releaseEvidenceRepository;
  final String? requiredReleaseId;

  Future<List<LabLearnerCatalogueEntry>> listAvailable() async {
    await _requireProductionRelease();
    return deliveryService.listAvailable();
  }

  Future<LabLearnerControlledDelivery> load({
    required String labId,
    required String versionId,
  }) async {
    await _requireProductionRelease();
    return deliveryService.load(labId: labId, versionId: versionId);
  }

  Future<void> _requireProductionRelease() async {
    final repository = releaseEvidenceRepository;
    if (repository == null) return;

    final releaseId = requiredReleaseId?.trim() ?? '';
    if (releaseId.isEmpty || !await repository.isReleased(releaseId)) {
      throw const LabProductionReleaseClosureException(
        'Production LAB population has not passed Q15 release closure.',
      );
    }
  }
}
