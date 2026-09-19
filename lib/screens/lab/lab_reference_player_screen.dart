import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';

class LabReferencePlayerScreen extends StatefulWidget {
  const LabReferencePlayerScreen({super.key, required this.mode});

  final LabMode mode;

  @override
  State<LabReferencePlayerScreen> createState() =>
      _LabReferencePlayerScreenState();
}

class _LabReferencePlayerScreenState extends State<LabReferencePlayerScreen> {
  static const _assetPath = 'content/lab_reference_confined_space_h2s_v2.json';

  late final InMemoryLabSessionStore _store;
  late final LabSessionEngine _engine;

  LabPackage? _package;
  LabSession? _session;
  String? _selectedOptionId;
  String? _error;
  bool _busy = false;
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
      final source = await rootBundle.loadString(_assetPath);
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
      setState(() {
        _session = updated;
        _selectedOptionId = null;
        _decisionStartedAt = DateTime.now();
        _busy = false;
      });

      if (updated.status != LabSessionStatus.completed) {
        final message = switch (widget.mode) {
          LabMode.guided =>
            'Decision confirmed: ' +
                selectedOption.quality.name.toUpperCase() +
                '.',
          LabMode.professional => 'Decision confirmed. Continue the scenario.',
          LabMode.assessment => 'Decision locked in. Continue.',
        };
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
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
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                package.metadata.title,
                style: TextStyle(
                  color: text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
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
              const SizedBox(height: 8),
              Text(
                'Choose one option. You can change your choice until you confirm it.',
                style: TextStyle(color: muted, height: 1.4),
              ),
            ],
          ),
        ),
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

  Widget _buildCompletion(
    BuildContext context,
    LabPackage package,
    LabSession session,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final endingTitle = _endingTitle(package, session.endingId);

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
                endingTitle,
                key: const ValueKey('lab-ending-title'),
                style: TextStyle(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
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

  String _endingTitle(LabPackage package, String? endingId) {
    for (final ending in package.endings) {
      if (ending['id']?.toString() == endingId) {
        return ending['title']?.toString() ?? _friendlyId(endingId);
      }
    }
    return _friendlyId(endingId);
  }

  String _friendlyId(String? value) {
    if (value == null || value.isEmpty) return 'Completed';
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }
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
                  option?.text ?? event.selectedOptionId,
                  style: TextStyle(
                    color: text,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  option == null
                      ? event.consequenceId
                      : option.quality.name.toUpperCase() +
                            ' • ' +
                            event.consequenceId,
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
