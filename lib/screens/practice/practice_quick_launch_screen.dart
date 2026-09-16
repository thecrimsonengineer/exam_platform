import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/learning_twin/coaching/learning_twin_practice_context.dart';
import '../../features/learning_twin/integration/learning_twin_pre_practice_guidance.dart';
import '../../services/practice/practice_mode_service.dart';
import '../courses/csp/quiz/quiz_screen.dart';

typedef PracticePlanBuilder =
    Future<PracticeSessionPlan> Function(PracticeMode mode);

typedef PracticeSessionBuilder = Widget Function(PracticeSessionPlan plan);

class PracticeQuickLaunchScreen extends StatefulWidget {
  const PracticeQuickLaunchScreen({
    super.key,
    required this.mode,
    required this.isDarkMode,
    this.planBuilder,
    this.sessionBuilder,
  });

  final PracticeMode mode;
  final bool isDarkMode;
  final PracticePlanBuilder? planBuilder;
  final PracticeSessionBuilder? sessionBuilder;

  @override
  State<PracticeQuickLaunchScreen> createState() =>
      _PracticeQuickLaunchScreenState();
}

class _PracticeQuickLaunchScreenState extends State<PracticeQuickLaunchScreen> {
  PracticeSessionPlan? _plan;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final builder = widget.planBuilder;
      final plan = builder != null
          ? await builder(widget.mode)
          : await PracticeModeService().build(widget.mode);

      if (!mounted) {
        return;
      }

      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  String get _title {
    switch (widget.mode) {
      case PracticeMode.dailyChallenge:
        return 'Daily Challenge';
      case PracticeMode.randomQuiz:
        return 'Random Quiz';
      case PracticeMode.weakAreas:
        return 'Weak Areas';
    }
  }

  String get _loadingCopy {
    switch (widget.mode) {
      case PracticeMode.dailyChallenge:
        return 'Preparing today’s published-question challenge...';
      case PracticeMode.randomQuiz:
        return 'Mixing published CSP11 questions...';
      case PracticeMode.weakAreas:
        return 'Checking your question history for an evidence-backed focus area...';
    }
  }

  LearningTwinPracticeContext _learningTwinContextFor(
    PracticeSessionPlan plan,
  ) {
    final mode = switch (plan.mode) {
      PracticeMode.dailyChallenge => LearningTwinPracticeMode.dailyChallenge,
      PracticeMode.randomQuiz => LearningTwinPracticeMode.randomQuiz,
      PracticeMode.weakAreas => LearningTwinPracticeMode.weakAreas,
    };

    return LearningTwinPracticeContext(
      mode: mode,
      questionCount: plan.questionCount,
      domainNumber: plan.domainNumber > 0 ? plan.domainNumber : null,
      usedFallback: plan.usedFallback,
    );
  }

  Widget _buildSession(PracticeSessionPlan plan) {
    final builder = widget.sessionBuilder;

    final session = builder != null
        ? builder(plan)
        : QuizScreen(
            domain: plan.domainNumber,
            customQuestions: plan.questions,
            sessionTitle: plan.title,
            sessionNotice: plan.notice,
          );

    return LearningTwinPracticeSessionHost(
      practiceContext: _learningTwinContextFor(plan),
      child: session,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final plan = _plan;

          if (plan != null) {
            return _buildSession(plan);
          }

          final scheme = Theme.of(context).colorScheme;

          return Scaffold(
            key: const ValueKey('practice-quick-launch-screen'),
            backgroundColor: scheme.surface,
            appBar: AppBar(
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                _title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _loading
                        ? _LoadingCard(
                            key: const ValueKey('practice-quick-loading'),
                            title: _title,
                            copy: _loadingCopy,
                          )
                        : _ErrorCard(
                            key: const ValueKey('practice-quick-error'),
                            message:
                                _error ??
                                'This practice session could not be prepared.',
                            onRetry: _prepare,
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({super.key, required this.title, required this.copy});

  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.error, size: 32),
          const SizedBox(height: 14),
          Text(
            'Unable to start practice',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }
}
