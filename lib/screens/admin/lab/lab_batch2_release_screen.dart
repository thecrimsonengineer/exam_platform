import 'package:flutter/material.dart';

import '../../../features/lab/lab_batch2_release.dart';
import '../../../features/lab/lab_batch2_release_operator.dart';
import '../../../features/lab/lab_production_release_closure.dart';

class LabBatch2ReleaseScreen extends StatefulWidget {
  const LabBatch2ReleaseScreen({
    super.key,
    required this.adminUserId,
    this.operator,
  });

  final String adminUserId;
  final LabBatch2ReleaseOperator? operator;

  @override
  State<LabBatch2ReleaseScreen> createState() => _LabBatch2ReleaseScreenState();
}

class _LabBatch2ReleaseScreenState extends State<LabBatch2ReleaseScreen> {
  late final LabBatch2ReleaseOperator _operator;
  final TextEditingController _confirmationController = TextEditingController();

  LabBatch2OperatorInspection? _inspection;
  String? _error;
  bool _loading = true;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _operator = widget.operator ?? LabBatch2ReleaseOperatorService.firestore();
    _refresh();
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final inspection = await _operator.inspect();
      if (!mounted) return;
      setState(() {
        _inspection = inspection;
        _loading = false;
        _confirmationController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _publish() async {
    final inspection = _inspection;
    if (inspection == null ||
        !inspection.canPublish ||
        _confirmationController.text != kBatch2ReleaseConfirmationPhrase ||
        _publishing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Batch 2 LABs?'),
        content: const Text(
          'This atomically publishes the second 10 validated LABs, their learner catalogue entries and immutable release evidence. It does not overwrite the original 10 LABs. The action cannot be repeated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            key: const ValueKey('batch2-dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('PUBLISH'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _publishing = true;
      _error = null;
    });

    try {
      final evidence = await _operator.publish(
        executedBy: widget.adminUserId,
        confirmationPhrase: kBatch2ReleaseConfirmationPhrase,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Batch 2 LAB release CLOSED. Evidence: ' +
                evidence.evidenceFingerprint,
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _error = error.toString();
      });
      return;
    }

    if (mounted) {
      setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _inspection;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LAB Batch 2 Release',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const ValueKey('batch2-refresh'),
            onPressed: _publishing ? null : _refresh,
            tooltip: 'Refresh Batch 2 production state',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const _Panel(
                    icon: Icons.lock_clock_rounded,
                    title: 'Frozen Batch 2 boundary',
                    body:
                        'Pre-catalogue SHA: ' +
                        kLspBatch2PrecatalogueClosedSha +
                        '\nValidation run: ' +
                        kLspBatch2PrecatalogueValidationRunId +
                        '\nExpected LABs: 10\nExpected Decisions: 50',
                  ),
                  const SizedBox(height: 14),
                  if (_error != null)
                    _Panel(
                      icon: Icons.error_outline_rounded,
                      title: 'Batch 2 operator error',
                      body: _error!,
                    ),
                  if (_error != null) const SizedBox(height: 14),
                  if (inspection != null) ...[
                    _Panel(
                      key: const ValueKey('batch2-state-panel'),
                      icon: _stateIcon(inspection.state),
                      title: inspection.stateLabel,
                      body:
                          'Environment: ' +
                          inspection.environmentId +
                          '\nManifest: ' +
                          inspection.manifestId +
                          '\nOriginal release closed: ' +
                          inspection.originalReleaseClosed.toString() +
                          '\nPublished: ' +
                          inspection.publishedCount.toString() +
                          '/' +
                          inspection.expectedLabCount.toString() +
                          '\nCatalogue: ' +
                          inspection.catalogueCount.toString() +
                          '/' +
                          inspection.expectedLabCount.toString(),
                    ),
                    const SizedBox(height: 14),
                    _Panel(
                      icon: Icons.fingerprint_rounded,
                      title: 'Manifest fingerprint',
                      body: inspection.manifestFingerprint,
                    ),
                    if (inspection.blockingReason != null) ...[
                      const SizedBox(height: 14),
                      _Panel(
                        icon: Icons.block_rounded,
                        title: 'Publication blocked',
                        body: inspection.blockingReason!,
                      ),
                    ],
                    if (inspection.evidence != null) ...[
                      const SizedBox(height: 14),
                      _Panel(
                        key: const ValueKey('batch2-evidence-panel'),
                        icon: Icons.verified_rounded,
                        title: 'Immutable Batch 2 release evidence',
                        body:
                            'Release: ' +
                            inspection.evidence!.releaseId +
                            '\nExecuted by: ' +
                            inspection.evidence!.executedBy +
                            '\nExecuted at: ' +
                            inspection.evidence!.executedAtIso +
                            '\nFingerprint: ' +
                            inspection.evidence!.evidenceFingerprint,
                      ),
                    ],
                    if (inspection.canPublish) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Additive production publication',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The original release is closed and Batch 2 is pristine. Type the exact phrase below to atomically publish all ten new LABs.',
                      ),
                      const SizedBox(height: 12),
                      const SelectableText(
                        kBatch2ReleaseConfirmationPhrase,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('batch2-confirmation'),
                        controller: _confirmationController,
                        enabled: !_publishing,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Confirmation phrase',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('batch2-release-action'),
                        onPressed:
                            !_publishing &&
                                _confirmationController.text ==
                                    kBatch2ReleaseConfirmationPhrase
                            ? _publish
                            : null,
                        icon: _publishing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.publish_rounded),
                        label: const Text('PUBLISH BATCH 2'),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  IconData _stateIcon(LabBatch2OperatorState state) {
    switch (state) {
      case LabBatch2OperatorState.blockedOriginalRelease:
        return Icons.lock_outline_rounded;
      case LabBatch2OperatorState.ready:
        return Icons.fact_check_rounded;
      case LabBatch2OperatorState.closed:
        return Icons.verified_user_rounded;
      case LabBatch2OperatorState.blockedPartial:
        return Icons.block_rounded;
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
