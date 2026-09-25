import 'package:flutter/material.dart';

import '../../../features/lab/lab_batch2_release_integration.dart';

class LabBatch2ReleaseScreen extends StatefulWidget {
  const LabBatch2ReleaseScreen({
    super.key,
    required this.adminUserId,
    this.releaseOperator,
    this.acceptanceService,
  });

  final String adminUserId;
  final LabBatch2ReleaseOperator? releaseOperator;
  final LabBatch2AcceptanceService? acceptanceService;

  @override
  State<LabBatch2ReleaseScreen> createState() => _LabBatch2ReleaseScreenState();
}

class _LabBatch2ReleaseScreenState extends State<LabBatch2ReleaseScreen> {
  late final LabBatch2ReleaseOperator _releaseOperator;
  late final LabBatch2AcceptanceService _acceptanceService;
  final TextEditingController _releaseConfirmation = TextEditingController();
  final TextEditingController _acceptanceConfirmation = TextEditingController();

  LabBatch2ReleaseInspection? _release;
  LabBatch2AcceptanceInspection? _acceptance;
  String? _error;
  bool _loading = true;
  bool _executing = false;

  @override
  void initState() {
    super.initState();
    _releaseOperator =
        widget.releaseOperator ?? LabBatch2ReleaseOperatorService.firestore();
    _acceptanceService =
        widget.acceptanceService ?? LabBatch2AcceptanceService.firestore();
    _refresh();
  }

  @override
  void dispose() {
    _releaseConfirmation.dispose();
    _acceptanceConfirmation.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final release = await _releaseOperator.inspect();
      final acceptance = await _acceptanceService.inspect();
      if (!mounted) return;
      setState(() {
        _release = release;
        _acceptance = acceptance;
        _loading = false;
        _releaseConfirmation.clear();
        _acceptanceConfirmation.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _refreshAfterFailure(Object error) async {
    try {
      final release = await _releaseOperator.inspect();
      final acceptance = await _acceptanceService.inspect();
      if (!mounted) return;
      setState(() {
        _release = release;
        _acceptance = acceptance;
        _loading = false;
        _error =
            error.toString() +
            '\nState was refreshed after the failed action. Retry Q16 only if the refreshed state is PRISTINE or RECOVERABLE_PARTIAL.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            error.toString() +
            '\nAutomatic state refresh also failed. Use Refresh before any further release action.';
      });
    }
  }

  Future<void> _runReleaseAction() async {
    final release = _release;
    if (release == null || _executing) return;
    final phrase = release.requiredConfirmationPhrase;
    if (phrase == null || _releaseConfirmation.text != phrase) return;

    setState(() {
      _executing = true;
      _error = null;
    });
    try {
      if (release.canRelease) {
        await _releaseOperator.executeRelease(
          executedBy: widget.adminUserId,
          confirmationPhrase: phrase,
        );
      } else {
        await _releaseOperator.closeExisting(
          executedBy: widget.adminUserId,
          confirmationPhrase: phrase,
        );
      }
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      await _refreshAfterFailure(error);
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  Future<void> _accept() async {
    final acceptance = _acceptance;
    if (acceptance == null ||
        !acceptance.canAccept ||
        _acceptanceConfirmation.text != kBatch2AcceptanceConfirmationPhrase ||
        _executing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Batch 2 live release?'),
        content: const Text(
          'This records immutable Batch 2 Q17 acceptance and atomically activates the staged 10 LAB catalogue entries. The original 10-LAB release remains unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            key: const ValueKey('batch2-accept-dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _executing = true;
      _error = null;
    });
    try {
      await _acceptanceService.acceptLiveRelease(
        acceptedBy: widget.adminUserId,
        confirmationPhrase: kBatch2AcceptanceConfirmationPhrase,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = _release;
    final acceptance = _acceptance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Batch 2 LAB Release',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const ValueKey('batch2-refresh'),
            onPressed: _executing ? null : _refresh,
            tooltip: 'Refresh Batch 2 release state',
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
                    icon: Icons.security_rounded,
                    title: 'Frozen release dependency',
                    body:
                        'Pre-catalogue SHA: ' +
                        kBatch2PreCatalogueClosedSha +
                        '\nValidation run: ' +
                        kBatch2PreCatalogueValidationRunId +
                        '\nLearner visibility: Batch 2 only',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _Panel(
                      icon: Icons.error_outline_rounded,
                      title: 'Operator error',
                      body: _error!,
                    ),
                  ],
                  if (release != null) ...[
                    const SizedBox(height: 14),
                    _Panel(
                      key: const ValueKey('batch2-q16-state'),
                      icon: release.isClosed
                          ? Icons.verified_rounded
                          : Icons.inventory_2_outlined,
                      title: 'Q16 extension: ' + release.stateLabel,
                      body:
                          'Environment: ' +
                          release.environmentId +
                          '\nManifest: ' +
                          release.manifestId +
                          '\nPublished: ' +
                          release.publishedCount.toString() +
                          '/' +
                          release.expectedLabCount.toString() +
                          '\nStaged catalogue: ' +
                          release.stagedCount.toString() +
                          '/' +
                          release.expectedLabCount.toString() +
                          (release.blockingReason == null
                              ? ''
                              : '\nBlocked: ' + release.blockingReason!),
                    ),
                    if (release.evidence != null) ...[
                      const SizedBox(height: 14),
                      _Panel(
                        icon: Icons.fingerprint_rounded,
                        title: 'Immutable Batch 2 Q16 evidence',
                        body:
                            'Release: ' +
                            release.evidence!.releaseId +
                            '\nFingerprint: ' +
                            release.evidence!.evidenceFingerprint,
                      ),
                    ],
                    if (release.requiredConfirmationPhrase != null) ...[
                      const SizedBox(height: 18),
                      SelectableText(
                        release.requiredConfirmationPhrase!,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('batch2-release-confirmation'),
                        controller: _releaseConfirmation,
                        enabled: !_executing,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Q16 confirmation phrase',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('batch2-release-action'),
                        onPressed:
                            !_executing &&
                                _releaseConfirmation.text ==
                                    release.requiredConfirmationPhrase
                            ? _runReleaseAction
                            : null,
                        icon: const Icon(Icons.publish_rounded),
                        label: Text(
                          release.canRelease
                              ? 'STAGE AND CLOSE BATCH 2'
                              : 'CLOSE EXISTING BATCH 2 STAGE',
                        ),
                      ),
                    ],
                  ],
                  if (acceptance != null) ...[
                    const SizedBox(height: 18),
                    _Panel(
                      key: const ValueKey('batch2-q17-state'),
                      icon:
                          acceptance.state == LabBatch2AcceptanceState.accepted
                          ? Icons.verified_user_rounded
                          : Icons.fact_check_outlined,
                      title: 'Q17 extension: ' + acceptance.stateLabel,
                      body:
                          'Activated learner catalogue: ' +
                          acceptance.activatedCount.toString() +
                          '/10' +
                          (acceptance.blockingReason == null
                              ? ''
                              : '\nBlocked: ' + acceptance.blockingReason!),
                    ),
                    if (acceptance.acceptance != null) ...[
                      const SizedBox(height: 14),
                      _Panel(
                        icon: Icons.verified_rounded,
                        title: 'Immutable Batch 2 Q17 acceptance',
                        body:
                            'Accepted by: ' +
                            acceptance.acceptance!.acceptedBy +
                            '\nAccepted at: ' +
                            acceptance.acceptance!.acceptedAtIso +
                            '\nFingerprint: ' +
                            acceptance.acceptance!.acceptanceFingerprint,
                      ),
                    ],
                    if (acceptance.canAccept) ...[
                      const SizedBox(height: 18),
                      const SelectableText(
                        kBatch2AcceptanceConfirmationPhrase,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('batch2-accept-confirmation'),
                        controller: _acceptanceConfirmation,
                        enabled: !_executing,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Q17 confirmation phrase',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('batch2-accept-action'),
                        onPressed:
                            !_executing &&
                                _acceptanceConfirmation.text ==
                                    kBatch2AcceptanceConfirmationPhrase
                            ? _accept
                            : null,
                        icon: const Icon(Icons.verified_user_rounded),
                        label: const Text('ACCEPT AND ACTIVATE BATCH 2'),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
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
  Widget build(BuildContext context) => Card(
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
