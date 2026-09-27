import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/micro_learning/micro_fact.dart';
import '../../services/micro_learning/startup_micro_fact_service.dart';
import 'startup_micro_fact_card.dart';

/// Fail-soft micro-learning presentation for transient loading states.
///
/// The block reads only from the existing validated local micro-fact runtime.
/// It never delays, authorizes, or otherwise participates in the host loading
/// flow. Until a fact is available it occupies no space.
class StartupMicroLearningBlock extends StatefulWidget {
  const StartupMicroLearningBlock({
    super.key,
    this.microFactService,
    this.rotationOrdinal,
  });

  final StartupMicroFactService? microFactService;
  final int? rotationOrdinal;

  @override
  State<StartupMicroLearningBlock> createState() =>
      _StartupMicroLearningBlockState();
}

class _StartupMicroLearningBlockState extends State<StartupMicroLearningBlock> {
  late final StartupMicroFactService _microFactService;
  MicroFact? _fact;

  @override
  void initState() {
    super.initState();
    _microFactService = widget.microFactService ?? StartupMicroFactService();
    unawaited(_loadFact());
  }

  Future<void> _loadFact() async {
    final fact = await _microFactService.load(
      rotationOrdinal:
          widget.rotationOrdinal ??
          StartupMicroFactService.dailyRotationOrdinal(DateTime.now()),
    );

    if (!mounted || fact == null) {
      return;
    }

    setState(() => _fact = fact);
  }

  @override
  Widget build(BuildContext context) {
    final fact = _fact;

    return AnimatedSize(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        reverseDuration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: fact == null
            ? const SizedBox.shrink(
                key: ValueKey('startup-micro-learning-empty'),
              )
            : Padding(
                key: ValueKey<String>(
                  'startup-micro-learning-${fact.microFactId}',
                ),
                padding: const EdgeInsets.only(top: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 462),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1018),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, 12),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: StartupMicroFactCard(
                        fact: fact,
                        highContrast: MediaQuery.highContrastOf(context),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
