import 'package:exam_platform/features/learning_twin/ui/learning_twin_ui.dart';
import 'package:flutter/material.dart';

class LearningTwinUiShowcaseScreen extends StatelessWidget {
  const LearningTwinUiShowcaseScreen({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase M2 · Twin UI System'),
        actions: [
          Semantics(
            label: 'Toggle dark mode',
            child: Switch(value: isDarkMode, onChanged: onDarkModeChanged),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 12.0 : 24.0;
            final maxWidth = constraints.maxWidth >= 1200 ? 1040.0 : 820.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                32,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'M2 isolation contract',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Reusable canonical-SVG presentation only. '
                                'No guidance decision logic, Firebase, avatar_maker, '
                                'production navigation, audio, voice or TTS.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Canonical avatar renderer',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          LearningTwinAvatar(size: 40),
                          LearningTwinAvatar(size: 48),
                          LearningTwinAvatar(
                            asset: LearningTwinAsset.explain,
                            size: 56,
                          ),
                          LearningTwinAvatar(
                            asset: LearningTwinAsset.success,
                            size: 72,
                          ),
                          LearningTwinAvatar(
                            asset: LearningTwinAsset.hero,
                            size: 120,
                            compactCrop: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const LearningTwinBubble(
                        message:
                            'This bubble can explain a concept without covering '
                            'the learner’s primary content or navigation.',
                      ),
                      const SizedBox(height: 16),
                      LearningTwinCard(
                        title: 'A focused learning nudge',
                        message:
                            'Cards are reserved for guidance that deserves more '
                            'space than a compact tip.',
                        asset: LearningTwinAsset.neutral,
                        actionLabel: 'Example action',
                        onAction: () {},
                        onDismiss: () {},
                      ),
                      const SizedBox(height: 16),
                      LearningTwinCompactTip(
                        message:
                            'Compact tips keep the Twin visible without becoming '
                            'a second navigation system.',
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      LearningTwinHero(
                        title: 'Naveed · Learning Guide',
                        message:
                            'Hero treatment is for large, deliberate moments such '
                            'as onboarding or meaningful milestones, not every screen.',
                        actionLabel: 'Example action',
                        onAction: () {},
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'M2 completion surfaces',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LearningTwinInlineBlock(
                        title: 'Inline explanation',
                        message:
                            'Inline blocks sit inside learning content when a short '
                            'explanation deserves more context than a compact tip.',
                        actionLabel: 'Example action',
                        onAction: () {},
                      ),
                      const SizedBox(height: 16),
                      LearningTwinCoachSheet(
                        title: 'Choose your next study step',
                        message:
                            'Coach-sheet content can be placed inside a controlled '
                            'modal surface later. M2 itself does not open navigation '
                            'or overlays.',
                        primaryActionLabel: 'Primary action',
                        onPrimaryAction: () {},
                        secondaryActionLabel: 'Secondary action',
                        onSecondaryAction: () {},
                        onDismiss: () {},
                      ),
                      const SizedBox(height: 16),
                      LearningTwinCelebration(
                        title: 'Milestone reached',
                        message:
                            'Celebration remains static in M2 so reduced-motion '
                            'preferences are respected by construction.',
                        actionLabel: 'Continue',
                        onAction: () {},
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: theme.colorScheme.tertiaryContainer,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'M2 presentation catalog is complete. It intentionally '
                            'uses no animation and does not decide when guidance is '
                            'allowed. Deterministic guidance contracts begin in M3.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
