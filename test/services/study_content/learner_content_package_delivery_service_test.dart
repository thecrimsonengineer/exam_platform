import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_runtime.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:exam_platform/services/study_content/learner_content_package_delivery_service.dart';
import 'package:exam_platform/services/study_content/published_content_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LearnerOnlineAccessSessionController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    LearnerLocalIdentity.activate('learner-fr10d');
    controller = LearnerOnlineAccessSessionController(
      validator: _AuthorizedValidator(),
      currentUserId: () => LearnerLocalIdentity.currentUserId,
    );
    LearnerOnlineAccessRuntime.bind(
      userId: 'learner-fr10d',
      controller: controller,
    );
    await controller.authorizeForUser('learner-fr10d');
  });

  tearDown(() {
    LearnerOnlineAccessRuntime.unbind(controller);
    controller.dispose();
    LearnerLocalIdentity.clear();
  });

  test('FR10D downloads, verifies and persists one changed package', () async {
    final package = _package();
    final gateway = _FakeGateway(package.descriptor);
    final downloader = _FakeDownloader(package.bytes);
    final service = LearnerContentPackageDeliveryService(
      gateway: gateway,
      downloader: downloader,
    );

    final content = await service.loadCompetency('d01_c01');

    expect(content.competencyId, 'd01_c01');
    expect(content.domainId, 'd01');
    expect(content.status, 'published');
    expect(downloader.downloadCount, 1);
    expect(gateway.requests.single.knownPackage, isNull);
  });

  test('FR10D unchanged reopen uses verified cache with zero downloads', () async {
    final package = _package();
    final gateway = _FakeGateway(package.descriptor);
    final downloader = _FakeDownloader(package.bytes);
    final service = LearnerContentPackageDeliveryService(
      gateway: gateway,
      downloader: downloader,
    );

    await service.loadCompetency('d01_c01');
    final reopened = await service.loadCompetency('d01_c01');

    expect(reopened.id, 'd01_c01-v5');
    expect(downloader.downloadCount, 1);
    expect(gateway.requests.length, 2);
    expect(gateway.requests.last.knownPackage, isNotNull);
  });

  test('FR10D refuses protected delivery while authorization is locked', () async {
    LearnerOnlineAccessRuntime.unbind(controller);

    final package = _package();
    final service = LearnerContentPackageDeliveryService(
      gateway: _FakeGateway(package.descriptor),
      downloader: _FakeDownloader(package.bytes),
    );

    await expectLater(
      service.loadCompetency('d01_c01'),
      throwsStateError,
    );
  });
}

class _Request {
  const _Request(this.competencyId, this.knownPackage);

  final String competencyId;
  final PublishedContentPackageDescriptor? knownPackage;
}

class _FakeGateway implements LearnerContentPackageGateway {
  _FakeGateway(this.descriptor);

  final PublishedContentPackageDescriptor descriptor;
  final List<_Request> requests = <_Request>[];

  @override
  Future<List<PublishedContentPackageDescriptor>> loadCatalog() async {
    return <PublishedContentPackageDescriptor>[descriptor];
  }

  @override
  Future<ContentPackageResolution> resolveCompetency({
    required String competencyId,
    PublishedContentPackageDescriptor? knownPackage,
  }) async {
    requests.add(_Request(competencyId, knownPackage));

    final current =
        knownPackage != null &&
        knownPackage.version == descriptor.version &&
        knownPackage.checksumSha256 == descriptor.checksumSha256;

    return ContentPackageResolution(
      descriptor: descriptor,
      current: current,
      signedUrl: current
          ? null
          : Uri.parse('https://example.test/content/d01_c01/v1.json.gz'),
    );
  }
}

class _FakeDownloader implements SignedContentPackageDownloader {
  _FakeDownloader(this.bytes);

  final List<int> bytes;
  int downloadCount = 0;

  @override
  Future<List<int>> download(Uri signedUrl) async {
    downloadCount++;
    return bytes;
  }
}

class _AuthorizedValidator implements LearnerOnlineAccessValidator {
  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    return LearnerOnlineAccessResult(
      status: LearnerOnlineAccessStatus.authorized,
      checkedAt: DateTime.utc(2026, 9, 22),
    );
  }
}

({PublishedContentPackageDescriptor descriptor, List<int> bytes}) _package() {
  final content = <String, dynamic>{
    'id': 'd01_c01-v5',
    'domainId': 'd01',
    'competencyId': 'd01_c01',
    'competencyNumber': 1,
    'title': 'Prevention-Through-Design',
    'status': 'published',
    'version': 5,
    'topics': <Map<String, dynamic>>[],
  };

  final envelope = <String, dynamic>{
    'schemaVersion': 1,
    'kind': 'content',
    'competencyId': 'd01_c01',
    'sourceVersion': 5,
    'content': content,
  };

  final encoded = utf8.encode(jsonEncode(envelope));
  final compressed = GZipEncoder().encode(encoded);

  return (
    descriptor: PublishedContentPackageDescriptor(
      competencyId: 'd01_c01',
      version: 1,
      checksumSha256: sha256.convert(compressed).toString(),
      compressedBytes: compressed.length,
    ),
    bytes: compressed,
  );
}
