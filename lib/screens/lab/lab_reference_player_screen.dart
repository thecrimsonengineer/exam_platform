import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';

import 'lab_learner_debrief_screen.dart';
import 'lab_scenario_catalog.dart';

class LabReferencePlayerScreen extends StatefulWidget {
  const LabReferencePlayerScreen({
    super.key,
    required this.mode,
    this.scenario = LabScenarioCatalog.confinedSpaceH2s,
    this.assetPath,
  });

  final LabMode mode;
  final LabScenarioDefinition scenario;
  final String? assetPath;

  @override
  State<LabReferencePlayerScreen> createState() =>
      _LabReferencePlayerScreenState();
}

class _LabReferencePlayerScreenState extends State<LabReferencePlayerScreen> {
  late final InMemoryLabSessionStore _store;
  late final LabSessionEngine _engine;

  LabPackage? _package;
  LabSession? _session;
  String? _selectedOptionId;
  _PendingConsequence? _pendingConsequence;
  String? _error;
  bool _busy = false;
  bool _statusExpanded = false;
  DateTime _decisionStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _store = InMemoryLabSessionStore();
    _engine = LabSessionEngine(store: _store);
    _loadLab();
  }

  Future<void> _loadLab() async {
    try {
      final source = await rootBundle.loadString(
        widget.assetPath ?? widget.scenario.assetPath,
      );
      final package = LabPackage.decode(source);
      final session = await _engine.startAttempt(
        package: package,
        sessionId: _newSessionId(),
        userId: 'local_lab_learner',
        mode: widget.mode,
      );
      if (!mounted) return;
      setState(() {
        _package = package;
        _session = session;
        _selectedOptionId = null;
        _pendingConsequence = null;
        _statusExpanded = false;
        _error = null;
        _decisionStartedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  String _newSessionId() =>
      'lab_' +
      widget.mode.name +
      '_' +
      DateTime.now().microsecondsSinceEpoch.toString();

  LabDecisionNode? _currentDecisionNode(
    LabPackage package,
    LabSession session,
  ) {
    for (final node in package.nodes) {
      if (node.id == session.currentNodeId && node is LabDecisionNode) {
        return node;
      }
    }
    return null;
  }

  Future<void> _confirmDecision() async {
    final package = _package;
    final session = _session;
    final optionId = _selectedOptionId;
    if (package == null || session == null || optionId == null || _busy) {
      return;
    }

    final node = _currentDecisionNode(package, session);
    if (node == null) return;

    final selectedOption = node.requireOption(optionId);
    final elapsed = DateTime.now()
        .difference(_decisionStartedAt)
        .inMilliseconds;

    setState(() => _busy = true);
    try {
      final updated = await _engine.commitDecision(
        package: package,
        session: session,
        optionId: optionId,
        responseTimeMs: elapsed < 0 ? 0 : elapsed,
      );
      if (!mounted) return;

      final consequenceId =
          selectedOption.consequenceId ?? selectedOption.consequence!.id;
      final presentation = widget.scenario.consequenceFor(consequenceId);

      setState(() {
        _session = updated;
        _selectedOptionId = null;
        _pendingConsequence = _PendingConsequence(
          selectedOptionText: selectedOption.text,
          presentation: presentation,
        );
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  void _continueAfterConsequence() {
    setState(() {
      _pendingConsequence = null;
      _decisionStartedAt = DateTime.now();
    });
  }

  Future<void> _replay() async {
    final package = _package;
    if (package == null || _busy) return;

    setState(() => _busy = true);
    try {
      final session = await _engine.startAttempt(
        package: package,
        sessionId: _newSessionId(),
        userId: 'local_lab_learner',
        mode: widget.mode,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _selectedOptionId = null;
        _pendingConsequence = null;
        _statusExpanded = false;
        _decisionStartedAt = DateTime.now();
        _busy = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return StudentGlassScaffold(
      backgroundColor: dark ? const Color(0xFF0A111D) : const Color(0xFFF4F8FF),
      appBar: AppBar(title: Text(_modeTitle(widget.mode) + ' LAB')),
      body: SafeArea(
        child: _error != null
            ? _ErrorState(message: _error!, onRetry: _loadLab)
            : _package == null || _session == null
            ? const Center(child: CircularProgressIndicator())
            : _buildLoaded(context, _package!, _session!),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    LabPackage package,
    LabSession session,
  ) {
    final pending = _pendingConsequence;
    if (pending != null) {
      return _buildConsequence(context, session, pending);
    }

    if (session.status == LabSessionStatus.completed) {
      return _buildCompletion(context, package, session);
    }

    final node = _currentDecisionNode(package, session);
    if (node == null) {
      return _ErrorState(
        message: 'The current LAB node is not a playable decision.',
        onRetry: _loadLab,
      );
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      key: const ValueKey('lab-reference-player'),
      padding: const EdgeInsets.all(20),
      children: [
        StudentGlassSurface(
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ModeBadge(mode: widget.mode),
                  const Spacer(),
                  Text(
                    'Decision ' +
                        (session.decisionHistory.length + 1).toString(),
                    key: const ValueKey('lab-decision-number'),
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                widget.scenario.title,
                style: TextStyle(
                  color: text,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'What is happening now',
                key: const ValueKey('lab-situation-heading'),
                style: TextStyle(
                  color: text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                node.prompt,
                key: const ValueKey('lab-decision-prompt'),
                style: TextStyle(
                  color: text,
                  fontSize: 17,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'What would you do?',
                key: const ValueKey('lab-action-heading'),
                style: TextStyle(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Choose one action. You can change your choice until you confirm it.',
                style: TextStyle(color: muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildLearnerContext(context, session),
        const SizedBox(height: 16),
        ...node.options.map((option) {
          final selected = _selectedOptionId == option.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('lab-option-' + option.id),
                borderRadius: BorderRadius.circular(18),
                onTap: _busy
                    ? null
                    : () => setState(() => _selectedOptionId = option.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: selected
                        ? primary.withValues(alpha: dark ? 0.18 : 0.10)
                        : (dark
                              ? Colors.white.withValues(alpha: 0.045)
                              : Colors.white.withValues(alpha: 0.72)),
                    border: Border.all(
                      color: selected
                          ? primary
                          : (dark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFDCE5F2)),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected ? primary : muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            color: text,
                            height: 1.4,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        FilledButton.icon(
          key: const ValueKey('lab-confirm-decision'),
          onPressed: _selectedOptionId == null || _busy
              ? null
              : _confirmDecision,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_rounded),
          label: const Text('CONFIRM DECISION'),
        ),
        const SizedBox(height: 12),
        Text(
          'Once confirmed, this decision is irreversible for this attempt.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _buildConsequence(
    BuildContext context,
    LabSession session,
    _PendingConsequence pending,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final completed = session.status == LabSessionStatus.completed;

    return ListView(
      key: const ValueKey('lab-consequence-screen'),
      padding: const EdgeInsets.all(20),
      children: [
        StudentGlassSurface(
          padding: const EdgeInsets.all(23),
          borderRadius: BorderRadius.circular(23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeBadge(mode: widget.mode),
              const SizedBox(height: 18),
              Text(
                'You decided',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pending.selectedOptionText,
                key: const ValueKey('lab-consequence-selected-action'),
                style: TextStyle(
                  color: text,
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 21),
              Text(
                'What happened next',
                key: const ValueKey('lab-consequence-heading'),
                style: TextStyle(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pending.presentation.observable,
                key: const ValueKey('lab-consequence-text'),
                style: TextStyle(color: text, height: 1.5),
              ),
              if (widget.mode == LabMode.guided) ...[
                const SizedBox(height: 20),
                Text(
                  'Why this mattered',
                  key: const ValueKey('lab-guided-consequence-insight'),
                  style: TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  pending.presentation.guidedInsight,
                  style: TextStyle(color: muted, height: 1.45),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildLearnerContext(context, session),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('lab-consequence-continue'),
          onPressed: _continueAfterConsequence,
          icon: Icon(
            completed ? Icons.flag_rounded : Icons.arrow_forward_rounded,
          ),
          label: Text(completed ? 'SEE OUTCOME' : 'CONTINUE'),
        ),
      ],
    );
  }

  Widget _buildLearnerContext(BuildContext context, LabSession session) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final status = widget.scenario.learnerStatus(
      session.stateValues,
      session.simulatedMinutes,
    );
    final evidence =
        session.evidenceUnlocked
            .map(widget.scenario.evidenceFor)
            .whereType<LabEvidencePresentation>()
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title));

    return StudentGlassSurface(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const ValueKey('lab-situation-status-toggle'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _statusExpanded = !_statusExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Situation status',
                      style: TextStyle(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    _statusExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          if (_statusExpanded) ...[
            const SizedBox(height: 14),
            for (final item in status)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.label, style: TextStyle(color: muted)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.value,
                      key: ValueKey(
                        'lab-status-' +
                            item.label.toLowerCase().replaceAll(' ', '-'),
                      ),
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Available evidence',
              key: const ValueKey('lab-available-evidence-heading'),
              style: TextStyle(
                color: text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in evidence)
                  OutlinedButton.icon(
                    key: ValueKey('lab-evidence-' + item.id),
                    onPressed: () => _showEvidence(context, item),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: Text(item.title),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEvidence(
    BuildContext context,
    LabEvidencePresentation evidence,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            key: ValueKey('lab-evidence-sheet-' + evidence.id),
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.title,
                  style: TextStyle(
                    color: text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  evidence.summary,
                  style: TextStyle(color: muted, height: 1.45),
                ),
                const SizedBox(height: 17),
                for (final detail in evidence.details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            detail,
                            style: TextStyle(color: text, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletion(
    BuildContext context,
    LabPackage package,
    LabSession session,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final ending = widget.scenario.endingFor(session.endingId);
    final journey = session.decisionHistory
        .map((event) => widget.scenario.decisionTitleFor(event.nodeId))
        .join(' → ');

    return ListView(
      key: const ValueKey('lab-completion-screen'),
      padding: const EdgeInsets.all(20),
      children: [
        StudentGlassSurface(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flag_circle_rounded, size: 42),
              const SizedBox(height: 14),
              Text(
                'LAB complete',
                style: TextStyle(
                  color: text,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ending.title,
                key: const ValueKey('lab-ending-title'),
                style: TextStyle(
                  color: text,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                ending.narrative,
                key: const ValueKey('lab-ending-narrative'),
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 17),
              Text(
                'Key turning point',
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                ending.keyTurningPoint,
                key: const ValueKey('lab-ending-turning-point'),
                style: TextStyle(color: muted, height: 1.45),
              ),
              if (journey.isNotEmpty) ...[
                const SizedBox(height: 17),
                Text(
                  'Your journey',
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  journey,
                  key: const ValueKey('lab-ending-journey'),
                  style: TextStyle(color: muted, height: 1.45),
                ),
              ],
              const SizedBox(height: 17),
              Text(
                _modeTitle(widget.mode) +
                    ' mode • ' +
                    session.decisionHistory.length.toString() +
                    ' decisions • ' +
                    session.simulatedMinutes.toString() +
                    ' simulated min',
                style: TextStyle(color: muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (session.decisionHistory.isNotEmpty)
          StudentGlassSurface(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decision timeline',
                  style: TextStyle(
                    color: text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < session.decisionHistory.length; i++)
                  _DecisionHistoryRow(
                    index: i + 1,
                    event: session.decisionHistory[i],
                    package: package,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('lab-view-debrief'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LabLearnerDebriefScreen(
                  package: package,
                  session: session,
                  scenario: widget.scenario,
                  onReplay: () {
                    _replay();
                  },
                ),
              ),
            );
          },
          icon: const Icon(Icons.insights_rounded),
          label: const Text('VIEW DEBRIEF'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('lab-replay-mode'),
          onPressed: _busy ? null : _replay,
          icon: const Icon(Icons.replay_rounded),
          label: Text(
            'REPLAY ' + _modeTitle(widget.mode).toUpperCase() + ' LAB',
          ),
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('BACK TO LAB MODES'),
        ),
      ],
    );
  }
}

class _PendingConsequence {
  const _PendingConsequence({
    required this.selectedOptionText,
    required this.presentation,
  });

  final String selectedOptionText;
  final LabConsequencePresentation presentation;
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final LabMode mode;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_modeIcon(mode), size: 17),
      label: Text(_modeTitle(mode) + ' mode'),
    );
  }
}

class _DecisionHistoryRow extends StatelessWidget {
  const _DecisionHistoryRow({
    required this.index,
    required this.event,
    required this.package,
  });

  final int index;
  final LabDecisionEvent event;
  final LabPackage package;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    LabDecisionOption? option;
    for (final node in package.nodes) {
      if (node.id != event.nodeId || node is! LabDecisionNode) continue;
      for (final candidate in node.options) {
        if (candidate.id == event.selectedOptionId) {
          option = candidate;
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(
              index.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option?.text ?? 'Decision recorded',
                  style: TextStyle(
                    color: text,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Decision recorded',
                  style: TextStyle(color: muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StudentGlassSurface(
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 38),
              const SizedBox(height: 12),
              const Text(
                'Unable to open this LAB',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _modeTitle(LabMode mode) => switch (mode) {
  LabMode.guided => 'Guided',
  LabMode.professional => 'Professional',
  LabMode.assessment => 'Assessment',
};

IconData _modeIcon(LabMode mode) => switch (mode) {
  LabMode.guided => Icons.explore_rounded,
  LabMode.professional => Icons.engineering_rounded,
  LabMode.assessment => Icons.fact_check_rounded,
};
