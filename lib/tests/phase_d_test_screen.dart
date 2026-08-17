import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/study_content/cloud_content_repository.dart';

class PhaseDTestScreen extends StatefulWidget {
  const PhaseDTestScreen({super.key});

  @override
  State<PhaseDTestScreen> createState() => _PhaseDTestScreenState();
}

class _PhaseDTestScreenState extends State<PhaseDTestScreen> {
  final List<String> _results = [];

  bool _running = false;

  void _log(String message) {
    if (!mounted) return;

    setState(() {
      _results.add(message);
    });
  }

  Future<void> _runTest() async {
    if (_running) return;

    setState(() {
      _running = true;
      _results.clear();
    });

    const testId = 'PHASE_D_TEST_DOCUMENT';

    try {
      _log('1/8 Firebase initialized.');

      final firestore = FirebaseFirestore.instance;
      final testRef = firestore
          .collection('contentVersions')
          .doc('draft_$testId');

      _log('2/8 Writing test document...');

      await testRef.set({
        'id': testId,
        'copyType': 'draft',
        'status': 'draft',
        'title': 'Phase D Test Document',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log('✓ Test document written.');

      _log('3/8 Reading test document...');

      final readDoc = await testRef.get();

      if (!readDoc.exists) {
        throw StateError('Test document could not be read.');
      }

      _log('✓ Test document read successfully.');

      _log('4/8 Updating draft status...');

      await testRef.update({
        'status': 'review',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final reviewDoc = await testRef.get();

      if (reviewDoc.data()?['status'] != 'review') {
        throw StateError('Draft status was not updated.');
      }

      _log('✓ Draft status changed to REVIEW.');

      _log('5/8 Creating published copy...');

      final publishedRef = firestore
          .collection('contentVersions')
          .doc('published_$testId');

      await publishedRef.set({
        'id': testId,
        'copyType': 'published',
        'status': 'published',
        'title': 'Phase D Test Document',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log('✓ Published copy created.');

      _log('6/8 Verifying draft still exists...');

      final draftStillExists = await testRef.get();

      if (!draftStillExists.exists) {
        throw StateError('CRITICAL: Draft disappeared after publishing.');
      }

      _log('✓ Draft copy still exists.');

      _log('7/8 Reading published copy...');

      final publishedDoc = await publishedRef.get();

      if (!publishedDoc.exists) {
        throw StateError('Published copy could not be read.');
      }

      _log('✓ Published copy read successfully.');

      _log('8/8 Cleaning up test documents...');

      await testRef.delete();
      await publishedRef.delete();

      _log('✓ Test documents deleted.');

      _log('');
      _log('🎉 PHASE D FIREBASE TEST PASSED');
    } catch (e) {
      _log('');
      _log('❌ PHASE D TEST FAILED');
      _log(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phase D Firebase Test')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CloudContentRepository D4 Test',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    children: _results
                        .map(
                          (result) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              result,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _running ? null : _runTest,
                    child: Text(
                      _running ? 'Testing Firebase...' : 'RUN PHASE D TEST',
                    ),
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
