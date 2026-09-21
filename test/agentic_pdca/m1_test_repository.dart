import '../../tool/agentic_pdca/m1_repository.dart';

const testSha = '94d060e37358915d03a2375ebc3af54808633e15';

final class CheckRepository implements M1TrustedRepository {
  CheckRepository({
    this.head = testSha,
    this.root = '.',
    this.dirty = const [],
    this.changed = const [],
    this.base = testSha,
  });
  String head;
  String base;
  List<String> dirty;
  List<String> changed;
  @override
  final String root;
  @override
  Future<M1RepositoryFacts> readFacts({
    required String approvedBaseSha,
  }) async => M1RepositoryFacts(
    root: root,
    head: head,
    ref: 'agentic-pdca-m1-001',
    mergeBase: base,
    changedPaths: changed,
    deletedTestPaths: const [],
    dirtyTrackedPaths: dirty,
    fileContents: const {},
    binaryPaths: const [],
  );
}
