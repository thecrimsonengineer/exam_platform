import 'dart:io';
import 'dart:typed_data';

class ChecksumEntry {
  const ChecksumEntry({required this.fileName, required this.sha256});

  final String fileName;
  final String sha256;
}

class ChecksumService {
  const ChecksumService();

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  String sha256Bytes(List<int> bytes) {
    final digest = _Sha256Digest()..add(bytes);
    return digest.close();
  }

  Future<String> sha256File(File file) async {
    final digest = _Sha256Digest();
    await for (final chunk in file.openRead()) {
      digest.add(chunk);
    }
    return digest.close();
  }

  String renderChecksumFile(Iterable<ChecksumEntry> entries) {
    final sorted = entries.toList()
      ..sort((left, right) => left.fileName.compareTo(right.fileName));

    final seenFileNames = <String>{};
    final buffer = StringBuffer();

    for (final entry in sorted) {
      _validateFileName(entry.fileName);
      if (!_sha256Pattern.hasMatch(entry.sha256)) {
        throw ArgumentError.value(
          entry.sha256,
          'sha256',
          'Expected a lowercase 64-character SHA-256 digest.',
        );
      }
      if (!seenFileNames.add(entry.fileName)) {
        throw ArgumentError.value(
          entry.fileName,
          'fileName',
          'Duplicate checksum file name.',
        );
      }

      buffer
        ..write(entry.sha256)
        ..write('  ')
        ..writeln(entry.fileName);
    }

    return buffer.toString();
  }

  Future<void> writeChecksumFile(
    File output,
    Iterable<ChecksumEntry> entries,
  ) async {
    final content = renderChecksumFile(entries);
    await output.parent.create(recursive: true);
    await output.writeAsString(content, flush: true);
  }

  static void _validateFileName(String fileName) {
    if (fileName.trim().isEmpty ||
        fileName.contains('\n') ||
        fileName.contains('\r')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'Checksum file names must be non-empty single-line values.',
      );
    }
  }
}

class _Sha256Digest {
  static const List<int> _initialState = <int>[
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];

  static const List<int> _roundConstants = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  final Uint32List _state = Uint32List.fromList(_initialState);
  final List<int> _buffer = <int>[];
  var _lengthInBytes = 0;
  var _closed = false;

  void add(List<int> bytes) {
    if (_closed) {
      throw StateError('Cannot add bytes after SHA-256 finalization.');
    }

    _lengthInBytes += bytes.length;
    var offset = 0;

    if (_buffer.isNotEmpty) {
      final needed = 64 - _buffer.length;
      final take = bytes.length < needed ? bytes.length : needed;
      _buffer.addAll(bytes.getRange(0, take));
      offset = take;

      if (_buffer.length == 64) {
        _processBlock(_buffer, 0);
        _buffer.clear();
      }
    }

    while (offset + 64 <= bytes.length) {
      _processBlock(bytes, offset);
      offset += 64;
    }

    if (offset < bytes.length) {
      _buffer.addAll(bytes.getRange(offset, bytes.length));
    }
  }

  String close() {
    if (_closed) {
      throw StateError('SHA-256 digest has already been finalized.');
    }
    _closed = true;

    final bitLength = _lengthInBytes * 8;
    final padding = <int>[..._buffer, 0x80];

    while (padding.length % 64 != 56) {
      padding.add(0);
    }

    for (var shift = 56; shift >= 0; shift -= 8) {
      padding.add((bitLength >> shift) & 0xff);
    }

    for (var offset = 0; offset < padding.length; offset += 64) {
      _processBlock(padding, offset);
    }

    return _state
        .map((word) => word.toRadixString(16).padLeft(8, '0'))
        .join();
  }

  void _processBlock(List<int> block, int offset) {
    final schedule = Uint32List(64);

    for (var index = 0; index < 16; index++) {
      final position = offset + index * 4;
      schedule[index] = _u32(
        (block[position] << 24) |
            (block[position + 1] << 16) |
            (block[position + 2] << 8) |
            block[position + 3],
      );
    }

    for (var index = 16; index < 64; index++) {
      final value15 = schedule[index - 15];
      final value2 = schedule[index - 2];
      final sigma0 =
          _rotateRight(value15, 7) ^
          _rotateRight(value15, 18) ^
          (value15 >>> 3);
      final sigma1 =
          _rotateRight(value2, 17) ^
          _rotateRight(value2, 19) ^
          (value2 >>> 10);
      schedule[index] = _u32(
        schedule[index - 16] +
            sigma0 +
            schedule[index - 7] +
            sigma1,
      );
    }

    var a = _state[0];
    var b = _state[1];
    var c = _state[2];
    var d = _state[3];
    var e = _state[4];
    var f = _state[5];
    var g = _state[6];
    var h = _state[7];

    for (var index = 0; index < 64; index++) {
      final sum1 =
          _rotateRight(e, 6) ^ _rotateRight(e, 11) ^ _rotateRight(e, 25);
      final choice = (e & f) ^ ((~e) & g);
      final temp1 = _u32(
        h + sum1 + choice + _roundConstants[index] + schedule[index],
      );
      final sum0 =
          _rotateRight(a, 2) ^ _rotateRight(a, 13) ^ _rotateRight(a, 22);
      final majority = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = _u32(sum0 + majority);

      h = g;
      g = f;
      f = e;
      e = _u32(d + temp1);
      d = c;
      c = b;
      b = a;
      a = _u32(temp1 + temp2);
    }

    _state[0] = _u32(_state[0] + a);
    _state[1] = _u32(_state[1] + b);
    _state[2] = _u32(_state[2] + c);
    _state[3] = _u32(_state[3] + d);
    _state[4] = _u32(_state[4] + e);
    _state[5] = _u32(_state[5] + f);
    _state[6] = _u32(_state[6] + g);
    _state[7] = _u32(_state[7] + h);
  }

  static int _rotateRight(int value, int count) {
    return _u32((value >>> count) | (value << (32 - count)));
  }

  static int _u32(int value) => value & 0xffffffff;
}
