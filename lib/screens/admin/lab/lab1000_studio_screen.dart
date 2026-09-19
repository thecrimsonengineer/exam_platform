import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../features/lab/lab_automated_lifecycle.dart';
import '../../../features/lab/lab_dqg300_evidence_store.dart';
import '../../../features/lab/lab_studio.dart';

class Lab1000StudioScreen extends StatefulWidget {
  const Lab1000StudioScreen({super.key});

  @override
  State<Lab1000StudioScreen> createState() => _Lab1000StudioScreenState();
}

class _Lab1000StudioScreenState extends State<Lab1000StudioScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _dqgController = TextEditingController();
  late final InMemoryLabDqg300EvidenceRepository _evidenceRepository;
  late final Lab1000StudioService _service;
  late final LabAutomatedLifecycleService _automatedLifecycle;

  LabStudioWorkspace? _workspace;
  String? _message;

  @override
  void initState() {
    super.initState();
    _evidenceRepository = InMemoryLabDqg300EvidenceRepository();
    _service = Lab1000StudioService(
      repository: InMemoryLabPublishedRepository(),
    );
    _automatedLifecycle = LabAutomatedLifecycleService(
      studio: _service,
      evidenceRepository: _evidenceRepository,
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _dqgController.dispose();
    super.dispose();
  }

  Future<void> _importFile() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'LAB JSON', extensions: <String>['json']),
      ],
    );
    if (file == null) return;
    _jsonController.text = await file.readAsString();
    _importText();
  }

  void _importText() {
    try {
      final workspace = _service.importJson(_jsonController.text);
      setState(() {
        _workspace = workspace;
        _message = workspace.report.isValid
            ? 'LAB JSON imported and validation passed.'
            : 'LAB JSON imported with validation issues.';
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
      });
    }
  }

  void _validate() {
    final workspace = _workspace;
    if (workspace == null) return;
    setState(() {
      _workspace = _service.validate(workspace);
      _message = _workspace!.report.isValid
          ? 'LAB1000 validation passed.'
          : 'Validation found blocking issues.';
    });
  }

  Future<void> _saveDqgEvidence() async {
    final workspace = _workspace;
    if (workspace == null) return;
    try {
      final bundle = const LabDqg300EvidenceCodec().decode(
        _dqgController.text,
      );
      if (bundle.labId != workspace.package.metadata.id ||
          bundle.versionId != workspace.package.metadata.versionId) {
        throw const LabStudioException(
          'DQG300-LAB evidence does not match the imported LAB ID/version.',
        );
      }
      await _evidenceRepository.save(bundle);
      if (!mounted) return;
      setState(() {
        _message = 'DQG300-LAB evidence saved for automated validation.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    }
  }

  Future<void> _runTestsAndPublish() async {
    final workspace = _workspace;
    if (workspace == null) return;
    try {
      if (_dqgController.text.trim().isNotEmpty) {
        await _saveDqgEvidence();
      }
      final result = await _automatedLifecycle.validateAndPublishStored(
        workspace: workspace,
      );
      if (!mounted) return;
      setState(() {
        _workspace = result.workspace;
        _jsonController.text = result.workspace.sourceJson;
        _message =
            'Automated LAB tests passed. Immutable version published without human approval.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    }
  }

  void _requestReview() {
    final workspace = _workspace;
    if (workspace == null) return;
    try {
      setState(() {
        _workspace = _service.requestReview(workspace);
        _jsonController.text = _workspace!.sourceJson;
        _message = 'LAB moved to REVIEW.';
      });
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }

  void _approve() {
    final workspace = _workspace;
    if (workspace == null) return;
    try {
      setState(() {
        _workspace = _service.approveReview(
          workspace,
          reviewerId: 'admin-reviewer',
        );
        _jsonController.text = _workspace!.sourceJson;
        _message = 'LAB moved to VALIDATED.';
      });
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }

  Future<void> _publish() async {
    final workspace = _workspace;
    if (workspace == null) return;
    try {
      final published = await _service.publish(workspace);
      if (!mounted) return;
      setState(() {
        _workspace = published;
        _jsonController.text = published.sourceJson;
        _message = 'Immutable LAB version published.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = _workspace;
    final preview = workspace == null
        ? null
        : _service.createPreview(workspace);
    final inspection = workspace == null ? null : _service.inspect(workspace);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'LAB1000 Studio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _StudioPanel(
              icon: Icons.data_object_rounded,
              title: 'JSON-first LAB authoring',
              body:
                  'Import or paste one LAB JSON package, validate the deterministic graph, inspect the authored state and routes, preview the package, review it and publish an immutable version.',
            ),
            const SizedBox(height: 14),
            const _StudioPanel(
              icon: Icons.account_tree_rounded,
              title: 'Deterministic runtime contract',
              body:
                  'Scene → Decision → Option → Consequence → State Mutation → Story Gate → Next Scene / Event / Ending. Runtime LLM branching remains forbidden.',
            ),
            const SizedBox(height: 14),
            const _StudioPanel(
              icon: Icons.verified_user_rounded,
              title: 'L1 boundary retained',
              body:
                  'The frozen L1 boundary established LAB-0 through LAB-3 only. L2 builds session, validation and Studio services on top without changing that deterministic foundation.',
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('lab1000-json-editor'),
              controller: _jsonController,
              minLines: 10,
              maxLines: 24,
              decoration: const InputDecoration(
                labelText: 'LAB JSON',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('lab1000-import-file'),
                  onPressed: _importFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('IMPORT FILE'),
                ),
                FilledButton.icon(
                  key: const ValueKey('lab1000-paste-import'),
                  onPressed: _importText,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('IMPORT / PASTE'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('lab1000-validate'),
                  onPressed: workspace == null ? null : _validate,
                  icon: const Icon(Icons.fact_check_rounded),
                  label: const Text('VALIDATE'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, key: const ValueKey('lab1000-message')),
            ],
            if (workspace != null && preview != null && inspection != null) ...[
              const SizedBox(height: 18),
              _StudioPanel(
                icon: Icons.preview_rounded,
                title: preview.title,
                body:
                    'LAB ' +
                    preview.labId +
                    ' • Version ' +
                    preview.versionId +
                    ' • ' +
                    preview.nodeCount.toString() +
                    ' nodes • ' +
                    preview.gateCount.toString() +
                    ' gates • ' +
                    preview.endingCount.toString() +
                    ' endings',
              ),
              const SizedBox(height: 14),
              _StudioPanel(
                icon: Icons.account_tree_rounded,
                title: 'Inspection',
                body:
                    'State: ' +
                    inspection.stateVariableIds.join(', ') +
                    '\nNodes: ' +
                    inspection.nodeIds.join(', ') +
                    '\nGates: ' +
                    inspection.gateIds.join(', ') +
                    '\nEndings: ' +
                    inspection.endingIds.join(', '),
              ),
              const SizedBox(height: 14),
              _StudioPanel(
                icon: workspace.report.isValid
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                title: 'Validation evidence',
                body:
                    'Lifecycle: ' +
                    workspace.lifecycle.name.toUpperCase() +
                    ' • Errors: ' +
                    workspace.report.errorCount.toString() +
                    ' • Warnings: ' +
                    workspace.report.warningCount.toString() +
                    ' • Deterministic simulations: ' +
                    workspace.report.simulationCount.toString(),
              ),
              const SizedBox(height: 14),
              const _StudioPanel(
                icon: Icons.auto_awesome_rounded,
                title: 'Automated publish gate',
                body:
                    'Paste or load the DQG300-LAB evidence bundle. RUN TESTS & PUBLISH re-runs structural validation, DQG300 for every Decision Node, exhaustive consequence/state/Story Gate routes and deterministic coverage before publishing. Human approval is not required on this path.',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('lab1000-dqg300-evidence-editor'),
                controller: _dqgController,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'DQG300-LAB evidence JSON',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('lab1000-save-dqg300-evidence'),
                    onPressed: workspace.lifecycle.name == 'draft'
                        ? _saveDqgEvidence
                        : null,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('SAVE DQG300 EVIDENCE'),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('lab1000-auto-publish'),
                    onPressed: workspace.lifecycle.name == 'draft'
                        ? _runTestsAndPublish
                        : null,
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('RUN TESTS & PUBLISH'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                key: const ValueKey('lab1000-legacy-lifecycle'),
                title: const Text('Legacy manual lifecycle'),
                subtitle: const Text(
                  'Compatibility path retained. Automated publishing is the primary LAB path.',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          key: const ValueKey('lab1000-review'),
                    onPressed: workspace.lifecycle.name == 'draft'
                        ? _requestReview
                        : null,
                    child: const Text('SEND TO REVIEW'),
                  ),
                  FilledButton(
                    key: const ValueKey('lab1000-approve'),
                    onPressed: workspace.lifecycle.name == 'review'
                        ? _approve
                        : null,
                    child: const Text('APPROVE / VALIDATE'),
                  ),
                        FilledButton(
                          key: const ValueKey('lab1000-publish'),
                          onPressed: workspace.lifecycle.name == 'validated'
                              ? _publish
                              : null,
                          child: const Text('PUBLISH IMMUTABLE VERSION'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudioPanel extends StatelessWidget {
  const _StudioPanel({
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
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: const Color(0xFF315EAA)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(body, style: const TextStyle(height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
