import 'package:flutter/material.dart';

import '../../../features/lab/lab_production_release_operator.dart';

class LabProductionReleaseScreen extends StatefulWidget {
  const LabProductionReleaseScreen({
    super.key,
    required this.adminUserId,
    this.operator,
  });

  final String adminUserId;
  final LabProductionReleaseOperator? operator;

  @override
  State<LabProductionReleaseScreen> createState() =>
      _LabProductionReleaseScreenState();
}

class _LabProductionReleaseScreenState
    extends State<LabProductionReleaseScreen> {
  late final LabProductionReleaseOperator _operator;
  final TextEditingController _confirmationController = TextEditingController();

  LabProductionOperatorInspection? _inspection;
  String? _error;
  bool _loading = true;
  bool _executing = false;

  @override
  void initState() {
    super.initState();
    _operator =
        widget.operator ?? LabProductionReleaseOperatorService.firestore();
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

  Future<void> _runAction() async {
    final inspection = _inspection;
    final phrase = inspection?.requiredConfirmationPhrase;
    if (inspection == null ||
        phrase == null ||
        _confirmationController.text != phrase ||
        _executing) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          inspection.canExecuteSeed
              ? 'Execute initial LAB release?'
              : 'Close existing LAB release?',
        ),
        content: Text(
          inspection.canExecuteSeed
              ? 'This creates the immutable 10-LAB production population and closes it with Q15 evidence. The action cannot overwrite an existing version.'
              : 'The 10-LAB population already exists. This action creates Q15 closure evidence only. It does not seed again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            key: const ValueKey('q16-dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CONFIRM'),
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
      final evidence = inspection.canExecuteSeed
          ? await _operator.executeInitialRelease(
              executedBy: widget.adminUserId,
              confirmationPhrase: phrase,
            )
          : await _operator.closeExistingRelease(
              executedBy: widget.adminUserId,
              confirmationPhrase: phrase,
            );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'LAB production release CLOSED. Evidence: ' +
                evidence.evidenceFingerprint,
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _executing = false;
        _error = error.toString();
      });
      return;
    }

    if (mounted) {
      setState(() => _executing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _inspection;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LAB Production Release',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const ValueKey('q16-refresh'),
            onPressed: _executing ? null : _refresh,
            tooltip: 'Refresh production state',
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
                  _ReleasePanel(
                    icon: Icons.lock_clock_rounded,
                    title: 'Frozen execution boundary',
                    body:
                        'Q15 closure SHA: ' +
                        kLspQ15ClosedSha +
                        '\nQ15 validation run: ' +
                        kLspQ15ClosureValidationRunId,
                  ),
                  const SizedBox(height: 14),
                  if (_error != null)
                    _ReleasePanel(
                      icon: Icons.error_outline_rounded,
                      title: 'Operator error',
                      body: _error!,
                    ),
                  if (_error != null) const SizedBox(height: 14),
                  if (inspection != null) ...[
                    _ReleasePanel(
                      key: const ValueKey('q16-state-panel'),
                      icon: _stateIcon(inspection.state),
                      title: inspection.displayStateLabel,
                      body:
                          'Environment: ' +
                          inspection.environmentId +
                          '\nManifest: ' +
                          inspection.manifestId +
                          '\nPublished: ' +
                          inspection.publishedCount.toString() +
                          '/' +
                          inspection.expectedLabCount.toString() +
                          '\nCatalogue: ' +
                          inspection.catalogueCount.toString() +
                          '/' +
                          inspection.expectedLabCount.toString() +
                          '\nCatalogue identities: ' +
                          inspection.catalogueIdentityCount.toString(),
                    ),
                    const SizedBox(height: 14),
                    _ReleasePanel(
                      icon: Icons.fingerprint_rounded,
                      title: 'Manifest fingerprint',
                      body: inspection.manifestFingerprint,
                    ),
                    if (inspection.isPermissionBlocked) ...[
                      const SizedBox(height: 14),
                      const _ReleasePanel(
                        icon: Icons.security_rounded,
                        title: 'Fail-closed protection active',
                        body:
                            'LAB scenarios remain unavailable to learners. No seed, closure, or release action is permitted until administrator Firestore access is verified.',
                      ),
                    ],
                    if (inspection.blockingReason != null) ...[
                      const SizedBox(height: 14),
                      _ReleasePanel(
                        icon: Icons.block_rounded,
                        title: 'Automatic action blocked',
                        body: inspection.blockingReason!,
                      ),
                    ],
                    if (inspection.evidence != null) ...[
                      const SizedBox(height: 14),
                      _ReleasePanel(
                        key: const ValueKey('q16-evidence-panel'),
                        icon: Icons.verified_rounded,
                        title: 'Immutable Q15 release evidence',
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
                    if (inspection.requiredConfirmationPhrase != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        inspection.canExecuteSeed
                            ? 'Initial production seed'
                            : 'Closure-only recovery',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        inspection.canExecuteSeed
                            ? 'The production repositories are pristine. Type the exact phrase below to enable the one-shot Q14 seed plus Q15 closure.'
                            : 'All ten immutable LABs exist but Q15 closure is missing. Do not seed again. Type the exact phrase below to create closure evidence.',
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        inspection.requiredConfirmationPhrase!,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('q16-confirmation'),
                        controller: _confirmationController,
                        enabled: !_executing,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Confirmation phrase',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('q16-release-action'),
                        onPressed:
                            !_executing &&
                                _confirmationController.text ==
                                    inspection.requiredConfirmationPhrase
                            ? _runAction
                            : null,
                        icon: _executing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_open_rounded),
                        label: Text(
                          inspection.canExecuteSeed
                              ? 'EXECUTE INITIAL RELEASE'
                              : 'CLOSE EXISTING RELEASE',
                        ),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  IconData _stateIcon(LabProductionOperatorState state) {
    switch (state) {
      case LabProductionOperatorState.pristine:
        return Icons.inventory_2_outlined;
      case LabProductionOperatorState.completeUnclosed:
        return Icons.pending_actions_rounded;
      case LabProductionOperatorState.closed:
        return Icons.verified_user_rounded;
      case LabProductionOperatorState.blockedPartial:
        return Icons.block_rounded;
    }
  }
}

class _ReleasePanel extends StatelessWidget {
  const _ReleasePanel({
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
