import 'package:flutter/material.dart';

import '../../theme/motion/csp11_motion.dart';
import '../../widgets/motion/csp11_completion_reveal.dart';
import '../../widgets/motion/csp11_fade_in.dart';
import '../../widgets/motion/csp11_flip_card.dart';
import '../../widgets/motion/csp11_pressable.dart';
import '../../widgets/motion/csp11_slide_fade.dart';
import '../../widgets/motion/csp11_state_switcher.dart';

class MotionDiagnosticsScreen extends StatefulWidget {
  const MotionDiagnosticsScreen({super.key});

  static const routeName = '/admin/motion-diagnostics';

  @override
  State<MotionDiagnosticsScreen> createState() =>
      _MotionDiagnosticsScreenState();
}

class _MotionDiagnosticsScreenState extends State<MotionDiagnosticsScreen> {
  int _replayToken = 0;
  int _completionToken = 0;
  int _pressCount = 0;
  bool _alternateState = false;
  bool _flipped = false;
  bool _celebratory = false;

  void _replay() => setState(() => _replayToken++);

  void _replayCompletion() {
    setState(() {
      _completionToken++;
      _celebratory = !_celebratory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Csp11MotionPreferences.reduced(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Motion diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              key: const ValueKey('motion-diagnostics-reduced-status'),
              leading: Icon(
                reduced ? Icons.accessibility_new_rounded : Icons.motion_photos_on,
              ),
              title: const Text('Reduced motion'),
              subtitle: Text(
                reduced
                    ? 'Enabled by the operating system. Spatial motion is reduced.'
                    : 'Not enabled. Standard CSP11 motion is active.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            key: const ValueKey('motion-diagnostics-replay'),
            onPressed: _replay,
            child: const Text('Replay fade and slide'),
          ),
          const SizedBox(height: 12),
          Csp11FadeIn(
            key: ValueKey<String>('motion-fade-$_replayToken'),
            child: const _DiagnosticTile(
              title: 'Fade reveal',
              subtitle: 'Status and lightweight information reveal.',
            ),
          ),
          const SizedBox(height: 12),
          Csp11SlideFade(
            key: ValueKey<String>('motion-slide-$_replayToken'),
            child: const _DiagnosticTile(
              title: 'Slide + fade',
              subtitle: 'Navigation and deterministic state progression.',
            ),
          ),
          const SizedBox(height: 12),
          Csp11StateSwitcher(
            child: _DiagnosticTile(
              key: ValueKey<bool>(_alternateState),
              title: _alternateState ? 'State B' : 'State A',
              subtitle: 'Shared state transition without business logic.',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('motion-diagnostics-toggle-state'),
            onPressed: () => setState(() => _alternateState = !_alternateState),
            child: const Text('Toggle state'),
          ),
          const SizedBox(height: 12),
          Csp11Pressable(
            onTap: () => setState(() => _pressCount++),
            child: _DiagnosticTile(
              title: 'Press interaction',
              subtitle: 'Press count: $_pressCount',
            ),
          ),
          const SizedBox(height: 12),
          Csp11CompletionReveal(
            key: ValueKey<String>('motion-completion-$_completionToken'),
            celebratory: _celebratory,
            child: _DiagnosticTile(
              title: _celebratory
                  ? 'Celebratory completion'
                  : 'Calm completion',
              subtitle: 'Completion treatment is semantic, not decorative.',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('motion-diagnostics-replay-completion'),
            onPressed: _replayCompletion,
            child: const Text('Replay completion'),
          ),
          const SizedBox(height: 12),
          Csp11FlipCard(
            isFlipped: _flipped,
            front: const _DiagnosticTile(
              title: 'Future Flashcard front',
              subtitle: 'Motion foundation only.',
            ),
            back: const _DiagnosticTile(
              title: 'Future Flashcard back',
              subtitle: 'No review engine is invented here.',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('motion-diagnostics-flip'),
            onPressed: () => setState(() => _flipped = !_flipped),
            child: const Text('Flip card'),
          ),
          const SizedBox(height: 20),
          Text(
            'This diagnostics page is local UI only. It performs no Firebase or '
            'Supabase reads or writes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}
