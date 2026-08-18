import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_content.dart';

/// Read-only Phase E1 inventory of the real local Study Content repository.
///
/// This screen deliberately does not write, delete, publish, migrate, or
/// change any local content. It reads the two existing SharedPreferences
/// stores directly so the inventory can distinguish stored records from
/// records that successfully deserialize into StudyContent objects.
class LocalRepositoryInventoryScreen extends StatefulWidget {
  const LocalRepositoryInventoryScreen({super.key});

  @override
  State<LocalRepositoryInventoryScreen> createState() =>
      _LocalRepositoryInventoryScreenState();
}

class _LocalRepositoryInventoryScreenState
    extends State<LocalRepositoryInventoryScreen> {
  static const _draftKey = 'csp11.study_content.drafts.v1';
  static const _publishedKey = 'csp11.study_content.published.v1';

  _Inventory? _inventory;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final preferences = await SharedPreferences.getInstance();
      final drafts = _inspectStore(preferences.getString(_draftKey));
      final published = _inspectStore(preferences.getString(_publishedKey));

      if (!mounted) return;
      setState(() {
        _inventory = _Inventory(drafts: drafts, published: published);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _inventory = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  _StoreInventory _inspectStore(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _StoreInventory(
        rawRecordCount: 0,
        validRecordCount: 0,
        malformedRecordCount: 0,
        records: [],
        rawState: 'EMPTY / KEY NOT PRESENT',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      return _StoreInventory(
        rawRecordCount: 0,
        validRecordCount: 0,
        malformedRecordCount: 1,
        records: [],
        rawState: 'INVALID JSON: $e',
      );
    }

    if (decoded is! List) {
      return const _StoreInventory(
        rawRecordCount: 0,
        validRecordCount: 0,
        malformedRecordCount: 1,
        records: [],
        rawState: 'INVALID ROOT TYPE: expected JSON array',
      );
    }

    final records = <_InventoryRecord>[];
    var malformed = 0;

    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is! Map) {
        malformed++;
        continue;
      }

      try {
        final json = Map<String, dynamic>.from(item);
        final content = StudyContent.fromJson(json);
        records.add(
          _InventoryRecord(
            sourceIndex: index,
            content: content,
          ),
        );
      } catch (_) {
        malformed++;
      }
    }

    return _StoreInventory(
      rawRecordCount: decoded.length,
      validRecordCount: records.length,
      malformedRecordCount: malformed,
      records: records,
      rawState: 'READ SUCCESSFULLY',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase E1 • Local Repository Inventory'),
        actions: [
          IconButton(
            tooltip: 'Refresh inventory',
            onPressed: _loading ? null : _loadInventory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _inventory == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText('Inventory failed:\n\n$_error'),
        ),
      );
    }

    final inventory = _inventory;
    if (inventory == null) {
      return const Center(child: Text('No inventory loaded.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final stores = [
          _StoreCard(
            title: 'DRAFT REPOSITORY',
            keyName: _draftKey,
            inventory: inventory.drafts,
          ),
          _StoreCard(
            title: 'PUBLISHED REPOSITORY',
            keyName: _publishedKey,
            inventory: inventory.published,
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSafetyBanner(),
                  const SizedBox(height: 20),
                  Text(
                    'Local CSP11 Content Baseline',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Read-only inspection of the existing SharedPreferences stores. '
                    'No content is written, deleted, published, migrated, or modified.',
                  ),
                  const SizedBox(height: 24),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: stores[0]),
                        const SizedBox(width: 20),
                        Expanded(child: stores[1]),
                      ],
                    )
                  else
                    Column(
                      children: [stores[0], const SizedBox(height: 20), stores[1]],
                    ),
                  const SizedBox(height: 28),
                  _buildNextStepCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
        color: Colors.green.withValues(alpha: .08),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'E1 SAFE MODE: This screen only reads the existing local stores.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'E1 completion condition: verify the actual Draft and Published '
                'inventory before beginning E2 Local → Firebase migration.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.title,
    required this.keyName,
    required this.inventory,
  });

  final String title;
  final String keyName;
  final _StoreInventory inventory;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SelectableText(keyName, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(label: 'Stored records', value: '${inventory.rawRecordCount}'),
                _Metric(label: 'Valid records', value: '${inventory.validRecordCount}'),
                _Metric(label: 'Malformed', value: '${inventory.malformedRecordCount}'),
              ],
            ),
            const SizedBox(height: 14),
            Text('Storage state: ${inventory.rawState}'),
            const Divider(height: 28),
            if (inventory.records.isEmpty)
              const Text('No valid StudyContent records found.')
            else
              ...inventory.records.map((record) => _RecordTile(record: record)),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final _InventoryRecord record;

  @override
  Widget build(BuildContext context) {
    final content = record.content;
    final questionCount = content.subtopics.fold<int>(
      0,
      (total, subtopic) => total + subtopic.questions.length,
    );

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(
        content.title.isEmpty ? '(Untitled content)' : content.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${content.id} • ${content.domainId} • ${content.competencyId}',
      ),
      children: [
        _DetailRow(label: 'Source index', value: '${record.sourceIndex}'),
        _DetailRow(label: 'Content ID', value: content.id),
        _DetailRow(label: 'Domain ID', value: content.domainId),
        _DetailRow(label: 'Competency ID', value: content.competencyId),
        _DetailRow(label: 'Competency number', value: '${content.competencyNumber}'),
        _DetailRow(label: 'Title', value: content.title),
        _DetailRow(label: 'Version', value: '${content.version}'),
        _DetailRow(label: 'Lifecycle status', value: content.status),
        _DetailRow(label: 'Topics/subtopics', value: '${content.subtopics.length} subtopics'),
        _DetailRow(label: 'Questions', value: '$questionCount'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '(empty)' : value)),
        ],
      ),
    );
  }
}

class _Inventory {
  const _Inventory({required this.drafts, required this.published});

  final _StoreInventory drafts;
  final _StoreInventory published;
}

class _StoreInventory {
  const _StoreInventory({
    required this.rawRecordCount,
    required this.validRecordCount,
    required this.malformedRecordCount,
    required this.records,
    required this.rawState,
  });

  final int rawRecordCount;
  final int validRecordCount;
  final int malformedRecordCount;
  final List<_InventoryRecord> records;
  final String rawState;
}

class _InventoryRecord {
  const _InventoryRecord({required this.sourceIndex, required this.content});

  final int sourceIndex;
  final StudyContent content;
}
