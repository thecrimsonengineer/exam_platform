import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/study_content/cloud_content_repository.dart';

class FirebaseRepositoryTestScreen extends StatefulWidget {
  const FirebaseRepositoryTestScreen({super.key});

  @override
  State<FirebaseRepositoryTestScreen> createState() =>
      _FirebaseRepositoryTestScreenState();
}

class _FirebaseRepositoryTestScreenState
    extends State<FirebaseRepositoryTestScreen> {
  final CloudContentRepository _repository = CloudContentRepository();

  String _status = 'Ready to test Firebase.';
  bool _running = false;

  Future<void> _runTest() async {
    setState(() {
      _running = true;
      _status = 'Running Firebase repository test...';
    });

    const testId = 'phase-d-firestore-test';

    try {
      final firestore = FirebaseFirestore.instance;

      setState(() {
        _status = '1/4 Firebase initialized. Writing test document...';
      });

      await firestore.collection('contentVersions').doc('draft_$testId').set({
        'id': testId,
        'copyType': 'draft',
        'status': 'draft',
        'title': 'Phase D Firestore Test',
        'version': 1,
        'domainId': 'test-domain',
        'competencyId': 'test-competency',
        'competencyNumber': 1,
        'subtopics': <Map<String, dynamic>>[],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _status = '2/4 Test document written. Reading through repository...';
      });

      final result = await _repository.loadDraft(testId);

      if (result == null) {
        throw StateError(
          'Repository could not read the test document from Firestore.',
        );
      }

      setState(() {
        _status =
            '3/4 Repository read successful. Deleting test document...';
      });

      await firestore.collection('contentVersions').doc('draft_$testId').delete();

      setState(() {
        _status =
            '4/4 SUCCESS\n\n'
            'Firebase connection: OK\n'
            'Firestore write: OK\n'
            'CloudContentRepository read: OK\n'
            'Firestore delete: OK\n\n'
            'The temporary test document has been removed.';
      });
    } catch (error) {
      setState(() {
        _status = 'FAILED\n\n$error';
      });
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase D Firebase Test'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'CloudContentRepository D4 Test',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(_status),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _running ? null : _runTest,
                  child: Text(
                    _running
                        ? 'Testing Firebase...'
                        : 'Run Firebase Repository Test',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}