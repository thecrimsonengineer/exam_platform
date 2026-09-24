import 'package:flutter/material.dart';

import '../../../features/lab/lab_production_deployment_acceptance.dart';
import '../../../features/lab/lab_production_release_operator.dart';
import 'lab_production_release_screen.dart';

class LabProductionDeploymentScreen extends StatefulWidget {
  const LabProductionDeploymentScreen({
    super.key,
    required this.adminUserId,
    this.service,
    this.releaseOperator,
    this.releaseScreenBuilder,
  });

  final String adminUserId;
  final LabProductionDeploymentAcceptanceService? service;
  final LabProductionReleaseOperator? releaseOperator;
  final Widget Function(LabProductionReleaseOperator operator)?
  releaseScreenBuilder;

  @override
  State<LabProductionDeploymentScreen> createState() =>
      _LabProductionDeploymentScreenState();
}

class _LabProductionDeploymentScreenState
    extends State<LabProductionDeploymentScreen> {
  late final LabProductionDeploymentAcceptanceService _service;
  late final LabProductionReleaseOperator _releaseOperator;

  LabProductionDeploymentStatus? _status;
  bool _loading = true;
  bool _executing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ?? LabProductionDeploymentAcceptanceService.firestore();
    _releaseOperator =
        widget.releaseOperator ??
        LabProductionReleaseOperatorService.firestore();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _service.inspect();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _runPreflight() async {
    setState(() {
      _executing = true;
      _error = null;
    });
    try {
      await _service.runPreflight(verifiedBy: widget.adminUserId);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _executing = false;
        _error = error.toString();
      });
      return;
    }
    if (mounted) setState(() => _executing = false);
  }

  Future<void> _openReleaseControl() async {
    final status = _status;
    if (status?.preflight == null) return;

    final guarded = LabQ17GuardedProductionReleaseOperator(
      delegate: _releaseOperator,
      deploymentRepository: _service.deploymentRepository,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            widget.releaseScreenBuilder?.call(guarded) ??
            LabProductionReleaseScreen(
              adminUserId: widget.adminUserId,
              operator: guarded,
            ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _runAcceptance() async {
    setState(() {
      _executing = true;
      _error = null;
    });
    try {
      await _service.acceptLiveRelease(acceptedBy: widget.adminUserId);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _executing = false;
        _error = error.toString();
      });
      return;
    }
    if (mounted) setState(() => _executing = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final inspection = status?.operatorInspection;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LAB Deployment & Acceptance',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _executing ? null : _refresh,
            tooltip: 'Refresh live state',
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
                    icon: Icons.shield_outlined,
                    title: 'Frozen Q16 boundary',
                    body:
                        'Closure SHA: ' +
                        kLspQ16ClosedSha +
                        '\nValidation run: ' +
                        kLspQ16ClosureValidationRunId +
                        '\nExpected Firebase project: ' +
                        kExpectedProductionFirebaseProjectId,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _Panel(
                      icon: Icons.error_outline_rounded,
                      title: 'Deployment check failed',
                      body: _error!,
                    ),
                  ],
                  if (inspection != null) ...[
                    const SizedBox(height: 14),
                    _Panel(
                      key: const ValueKey('q17-live-state'),
                      icon: Icons.cloud_done_outlined,
                      title: 'Live state: ' + inspection.stateLabel,
                      body:
                          'Environment: ' +
                          inspection.environmentId +
                          '\nPublished: ' +
                          inspection.publishedCount.toString() +
                          '/' +
                          inspection.expectedLabCount.toString() +
                          '\nCatalogue: ' +
                          inspection.catalogueCount.toString() +
                          '/' +
                          inspection.expectedLabCount.toString(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _Panel(
                    key: const ValueKey('q17-preflight-state'),
                    icon: status?.preflight == null
                        ? Icons.rule_folder_outlined
                        : Icons.verified_outlined,
                    title: status?.preflight == null
                        ? 'Deployment preflight required'
                        : 'Deployment preflight verified',
                    body: status?.preflight == null
                        ? 'Deploy the Q17 Firestore rules to csp11-exam-platform first. Then run this preflight. A successful immutable marker proves the Q17 rules are active on the intended project.'
                        : 'Fingerprint: ' +
                              status!.preflight!.preflightFingerprint +
                              '\nVerified by: ' +
                              status.preflight!.verifiedBy +
                              '\nVerified at: ' +
                              status.preflight!.verifiedAtIso,
                  ),
                  const SizedBox(height: 12),
                  if (status?.preflight == null)
                    FilledButton.icon(
                      key: const ValueKey('q17-run-preflight'),
                      onPressed:
                          _executing ||
                              inspection?.state ==
                                  LabProductionOperatorState.blockedPartial
                          ? null
                          : _runPreflight,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('RUN DEPLOYMENT PREFLIGHT'),
                    ),
                  if (status?.preflight != null &&
                      inspection != null &&
                      !inspection.isClosed) ...[
                    FilledButton.icon(
                      key: const ValueKey('q17-open-release'),
                      onPressed: _executing ? null : _openReleaseControl,
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('OPEN PRODUCTION RELEASE CONTROL'),
                    ),
                  ],
                  if (status?.preflight != null &&
                      inspection?.isClosed == true &&
                      status?.acceptance == null) ...[
                    FilledButton.icon(
                      key: const ValueKey('q17-run-acceptance'),
                      onPressed: _executing ? null : _runAcceptance,
                      icon: const Icon(Icons.task_alt_rounded),
                      label: const Text('RUN LIVE RELEASE ACCEPTANCE'),
                    ),
                  ],
                  if (status?.acceptance != null) ...[
                    const SizedBox(height: 14),
                    _Panel(
                      key: const ValueKey('q17-acceptance-state'),
                      icon: Icons.workspace_premium_outlined,
                      title: 'LIVE RELEASE ACCEPTED',
                      body:
                          'Acceptance ID: ' +
                          status!.acceptance!.acceptanceId +
                          '\nAccepted by: ' +
                          status.acceptance!.acceptedBy +
                          '\nAccepted at: ' +
                          status.acceptance!.acceptedAtIso +
                          '\nFingerprint: ' +
                          status.acceptance!.acceptanceFingerprint,
                    ),
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
