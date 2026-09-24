import 'package:flutter/material.dart';

import '../../../features/lab/lab_production_deployment_acceptance.dart';

class LabProductionDeploymentAcceptanceScreen extends StatefulWidget {
  const LabProductionDeploymentAcceptanceScreen({
    super.key,
    required this.adminUserId,
    this.operator,
  });

  final String adminUserId;
  final LabProductionDeploymentAcceptanceOperator? operator;

  @override
  State<LabProductionDeploymentAcceptanceScreen> createState() =>
      _LabProductionDeploymentAcceptanceScreenState();
}

class _LabProductionDeploymentAcceptanceScreenState
    extends State<LabProductionDeploymentAcceptanceScreen> {
  late final LabProductionDeploymentAcceptanceOperator _operator;
  final TextEditingController _confirmationController = TextEditingController();

  LabProductionDeploymentInspection? _inspection;
  String? _error;
  bool _loading = true;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _operator =
        widget.operator ??
        LabProductionDeploymentAcceptanceService.firestore();
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

  Future<void> _accept() async {
    final inspection = _inspection;
    if (inspection == null ||
        !inspection.canAccept ||
        _confirmationController.text != kQ17AcceptanceConfirmationPhrase ||
        _accepting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept live LAB release?'),
        content: const Text(
          'This records immutable Q17 live-release acceptance for the already CLOSED 10-LAB production population. It does not publish, overwrite, delete or reseed LAB content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            key: const ValueKey('q17-dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _accepting = true;
      _error = null;
    });

    try {
      final acceptance = await _operator.acceptLiveRelease(
        acceptedBy: widget.adminUserId,
        confirmationPhrase: kQ17AcceptanceConfirmationPhrase,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'LAB live release ACCEPTED. Evidence: ' +
                acceptance.acceptanceFingerprint,
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _error = error.toString();
      });
      return;
    }

    if (mounted) {
      setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _inspection;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LAB Deployment Acceptance',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const ValueKey('q17-refresh'),
            onPressed: _accepting ? null : _refresh,
            tooltip: 'Refresh live deployment state',
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
                  const _AcceptancePanel(
                    icon: Icons.lock_clock_rounded,
                    title: 'Frozen Q17 boundary',
                    body:
                        'Q16 closure SHA: ' +
                        kLspQ16ClosedSha +
                        '\nQ16 validation run: ' +
                        kLspQ16ClosureValidationRunId +
                        '\nExpected environment: ' +
                        kExpectedLabProductionEnvironmentId,
                  ),
                  const SizedBox(height: 14),
                  if (_error != null)
                    _AcceptancePanel(
                      icon: Icons.error_outline_rounded,
                      title: 'Acceptance error',
                      body: _error!,
                    ),
                  if (_error != null) const SizedBox(height: 14),
                  if (inspection != null) ...[
                    _AcceptancePanel(
                      key: const ValueKey('q17-state-panel'),
                      icon: _stateIcon(inspection.state),
                      title: inspection.stateLabel,
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
                    _AcceptancePanel(
                      icon: Icons.fingerprint_rounded,
                      title: 'Frozen release fingerprints',
                      body:
                          'Manifest: ' +
                          inspection.manifestFingerprint +
                          (inspection.evidence == null
                              ? ''
                              : '\nQ15 evidence: ' +
                                    inspection.evidence!.evidenceFingerprint),
                    ),
                    if (inspection.blockingReason != null) ...[
                      const SizedBox(height: 14),
                      _AcceptancePanel(
                        icon: Icons.block_rounded,
                        title: 'Acceptance blocked',
                        body: inspection.blockingReason!,
                      ),
                    ],
                    if (inspection.acceptance != null) ...[
                      const SizedBox(height: 14),
                      _AcceptancePanel(
                        key: const ValueKey('q17-acceptance-panel'),
                        icon: Icons.verified_rounded,
                        title: 'Immutable Q17 acceptance',
                        body:
                            'Accepted by: ' +
                            inspection.acceptance!.acceptedBy +
                            '\nAccepted at: ' +
                            inspection.acceptance!.acceptedAtIso +
                            '\nFingerprint: ' +
                            inspection.acceptance!.acceptanceFingerprint,
                      ),
                    ],
                    if (inspection.canAccept) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Live release acceptance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The production project, Q16 closure, 10-LAB population and 50-decision evidence all match. Type the exact phrase below to record immutable acceptance.',
                      ),
                      const SizedBox(height: 12),
                      const SelectableText(
                        kQ17AcceptanceConfirmationPhrase,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('q17-confirmation'),
                        controller: _confirmationController,
                        enabled: !_accepting,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Confirmation phrase',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('q17-accept-action'),
                        onPressed:
                            !_accepting &&
                                _confirmationController.text ==
                                    kQ17AcceptanceConfirmationPhrase
                            ? _accept
                            : null,
                        icon: _accepting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_user_rounded),
                        label: const Text('ACCEPT LIVE RELEASE'),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  IconData _stateIcon(LabProductionDeploymentState state) {
    switch (state) {
      case LabProductionDeploymentState.blocked:
        return Icons.block_rounded;
      case LabProductionDeploymentState.ready:
        return Icons.fact_check_rounded;
      case LabProductionDeploymentState.accepted:
        return Icons.verified_user_rounded;
    }
  }
}

class _AcceptancePanel extends StatelessWidget {
  const _AcceptancePanel({
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
