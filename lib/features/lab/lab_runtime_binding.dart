import 'package:cloud_firestore/cloud_firestore.dart';

import 'lab_firestore_repositories.dart';
import 'lab_learner_catalogue.dart';

class LabLearnerRuntimeBinding {
  const LabLearnerRuntimeBinding({
    required this.deliveryService,
  });

  factory LabLearnerRuntimeBinding.firestore({
    FirebaseFirestore? firestore,
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
    );
  }

  final LabLearnerControlledDeliveryService deliveryService;

  Future<List<LabLearnerCatalogueEntry>> listAvailable() =>
      deliveryService.listAvailable();

  Future<LabLearnerControlledDelivery> load({
    required String labId,
    required String versionId,
  }) =>
      deliveryService.load(labId: labId, versionId: versionId);
}
