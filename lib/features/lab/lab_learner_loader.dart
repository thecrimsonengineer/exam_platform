import 'lab_contracts.dart';
import 'lab_studio.dart';

class LabLearnerPackageLoader {
  const LabLearnerPackageLoader({required this.repository});

  final LabPublishedRepository repository;

  Future<LabPackage> loadPublished({
    required String labId,
    required String versionId,
  }) async {
    final version = await repository.load(labId, versionId);
    if (version == null) {
      throw const LabStudioException('Published LAB version was not found.');
    }

    final package = LabPackage.decode(version.publishedJson);
    if (package.metadata.lifecycle != LabLifecycleStatus.published) {
      throw const LabStudioException(
        'Learner runtime accepts PUBLISHED LAB versions only.',
      );
    }
    if (package.metadata.id != labId ||
        package.metadata.versionId != versionId) {
      throw const LabStudioException(
        'Published LAB identity does not match the requested version.',
      );
    }
    return package;
  }
}
