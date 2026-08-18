import 'package:flutter/material.dart';

import '../models/study_content.dart';
import '../services/study_content/content_migration_service.dart';

class ContentMigrationScreen extends StatefulWidget {
  const ContentMigrationScreen({super.key});

  @override
  State<ContentMigrationScreen> createState() => _ContentMigrationScreenState();
}

class _ContentMigrationScreenState extends State<ContentMigrationScreen> {
  final _service = ContentMigrationService();

  MigrationReport? _report;
  String _message = 'Run Preview before migration.';
  bool _busy = false;

  Future<void> _preview() async {
    await _run(() async {
      final report = await _service.inspect();
      setState(() {
        _report = report;
        _message = 'Preview completed.';
      });
    });
  }

  Future<void> _migrate() async {
    await _run(() async {
      final report = await _service.migrateMissing();
      setState(() {
        _report = report;
        _message =
            'Migration completed. Migrated: ${report.migrated}, '
            'skipped: ${report.skipped}, conflicts: ${report.conflicts}.';
      });
    });
  }

  Future<void> _verify() async {
    await _run(() async {
      final report = await _service.verify();
      setState(() {
        _report = report;
        _message =
            'Verification completed. Matching: ${report.skipped}, '
            'conflicts: ${report.conflicts}.';
      });
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'ERROR: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: const Text('Phase E2 • Local → Firebase Migration')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'E2 CONTROLLED MIGRATION',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only missing local records are written. Existing matching cloud records are skipped. Existing non-matching cloud records are reported as conflicts and are not overwritten.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _preview,
                        icon: const Icon(Icons.search),
                        label: const Text('Preview'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _busy || report == null ? null : _migrate,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Migrate Missing'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _verify,
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_message),
                ],
              ),
            ),
          ),
          if (report != null) ...[
            const SizedBox(height: 20),
            _summary(report),
            const SizedBox(height: 20),
            ...report.items.map(_itemCard),
          ],
        ],
      ),
    );
  }

  Widget _summary(MigrationReport report) {
    final missing = report.items
        .where((item) => !item.cloudExists)
        .length;
    final matching = report.items
        .where((item) => item.cloudExists && item.cloudMatches)
        .length;
    final conflicts = report.items
        .where((item) => item.cloudExists && !item.cloudMatches)
        .length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _metric('Local records', report.items.length),
        _metric('Missing in cloud', missing),
        _metric('Matching', matching),
        _metric('Conflicts', conflicts),
        if (report.migrated > 0) _metric('Migrated', report.migrated),
      ],
    );
  }

  Widget _metric(String label, int value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(MigrationInventoryItem item) {
    final content = item.content;
    final state = !item.cloudExists
        ? 'MISSING IN FIREBASE'
        : item.cloudMatches
        ? 'MATCHING IN FIREBASE'
        : 'CONFLICT: CLOUD DIFFERS';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(content.title),
        subtitle: Text(
          '${item.copyType.name.toUpperCase()} • ${content.id}\n'
          'domain=${content.domainId} • competency=${content.competencyId}\n'
          'version=${content.version} • status=${content.status}\n'
          'subtopics=${content.subtopics.length} • questions=${_questionCount(content)}',
        ),
        isThreeLine: true,
        trailing: Text(
          state,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  int _questionCount(StudyContent content) {
    return content.subtopics.fold<int>(
      0,
      (total, subtopic) => total + subtopic.questions.length,
    );
  }
}
