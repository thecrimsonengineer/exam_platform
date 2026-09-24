import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/checksum_service.dart';

void main() {
  group('ChecksumService SHA-256', () {
    const service = ChecksumService();

    test('matches the empty-input SHA-256 vector', () {
      expect(
        service.sha256Bytes(const <int>[]),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('matches the abc SHA-256 vector', () {
      expect(
        service.sha256Bytes(const <int>[97, 98, 99]),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('hashes a large file through the streaming path', () async {
      final directory = await Directory.systemTemp.createTemp(
        'rel_gov_sha256_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });

      final file = File('${directory.path}/million-a.bin');
      await file.writeAsBytes(List<int>.filled(1000000, 97), flush: true);

      expect(
        await service.sha256File(file),
        'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0',
      );
    });
  });

  group('ChecksumService checksums.sha256', () {
    const service = ChecksumService();
    final zeroHash = List<String>.filled(64, '0').join();
    final fHash = List<String>.filled(64, 'f').join();

    test('renders deterministic file-name order', () {
      final content = service.renderChecksumFile(<ChecksumEntry>[
        ChecksumEntry(fileName: 'z/app.zip', sha256: fHash),
        ChecksumEntry(fileName: 'a/app.apk', sha256: zeroHash),
      ]);

      expect(
        content,
        '$zeroHash  a/app.apk\n$fHash  z/app.zip\n',
      );
    });

    test('rejects malformed hashes', () {
      expect(
        () => service.renderChecksumFile(
          const <ChecksumEntry>[
            ChecksumEntry(fileName: 'app.apk', sha256: 'not-a-sha'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate file names', () {
      expect(
        () => service.renderChecksumFile(<ChecksumEntry>[
          ChecksumEntry(fileName: 'app.apk', sha256: zeroHash),
          ChecksumEntry(fileName: 'app.apk', sha256: fHash),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects multiline file names', () {
      expect(
        () => service.renderChecksumFile(<ChecksumEntry>[
          ChecksumEntry(fileName: 'app.apk\nother.bin', sha256: zeroHash),
        ]),
        throwsArgumentError,
      );
    });

    test('writes the deterministic checksum file', () async {
      final directory = await Directory.systemTemp.createTemp(
        'rel_gov_checksums_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });

      final output = File('${directory.path}/checksums.sha256');
      await service.writeChecksumFile(output, <ChecksumEntry>[
        ChecksumEntry(fileName: 'app.apk', sha256: zeroHash),
      ]);

      expect(await output.readAsString(), '$zeroHash  app.apk\n');
    });
  });
}
