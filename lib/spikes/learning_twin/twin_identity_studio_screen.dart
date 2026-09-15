import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'twin_identity_candidate.dart';

class TwinIdentityStudioScreen extends StatefulWidget {
  const TwinIdentityStudioScreen({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.showAuthoringLane = true,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final bool showAuthoringLane;

  @override
  State<TwinIdentityStudioScreen> createState() =>
      _TwinIdentityStudioScreenState();
}

class _TwinIdentityStudioScreenState extends State<TwinIdentityStudioScreen> {
  static const _curatedCandidates = <TwinIdentityCandidate>[
    TwinIdentityCandidate.curated(
      id: 'professional-neutral',
      label: 'Professional · Neutral',
      intent: 'calm/default',
      assetPath:
          'assets/learning_twin/candidates/naveed_professional_neutral.svg',
    ),
    TwinIdentityCandidate.curated(
      id: 'professional-explain',
      label: 'Professional · Explain',
      intent: 'teach/explain',
      assetPath:
          'assets/learning_twin/candidates/naveed_professional_explain.svg',
    ),
    TwinIdentityCandidate.curated(
      id: 'professional-success',
      label: 'Professional · Success',
      intent: 'encourage/celebrate',
      assetPath:
          'assets/learning_twin/candidates/naveed_professional_success.svg',
    ),
    TwinIdentityCandidate.curated(
      id: 'professional-fullbody',
      label: 'Professional · Full body',
      intent: 'hero/large surface',
      assetPath:
          'assets/learning_twin/candidates/naveed_professional_fullbody.svg',
    ),
  ];

  NonPersistentAvatarMakerController? _controller;
  final List<TwinIdentityCandidate> _makerCandidates = [];
  String? _captureError;

  @override
  void initState() {
    super.initState();
    if (widget.showAuthoringLane) {
      _controller = NonPersistentAvatarMakerController(
        locale: const Locale('en'),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _captureMakerCandidate() {
    final controller = _controller;
    if (controller == null || controller.displayedAvatarSVG.isEmpty) {
      setState(() {
        _captureError = 'Avatar initialization is still completing.';
      });
      return;
    }

    try {
      final json = controller.getJsonOptionsSync();
      final svg = controller.getAvatarSVGSync();
      final sequence = _makerCandidates.length + 1;

      setState(() {
        _makerCandidates.add(
          TwinIdentityCandidate.avatarMaker(
            id: 'maker-$sequence',
            label: 'Maker candidate $sequence',
            svg: svg,
            json: json,
          ),
        );
        _captureError = null;
      });
    } catch (error) {
      setState(() {
        _captureError = error.toString();
      });
    }
  }

  Future<void> _copyCandidatePayload(String label, String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase M1 · Twin Identity Studio'),
        actions: [
          Semantics(
            label: 'Toggle dark mode',
            child: Switch(
              value: widget.isDarkMode,
              onChanged: widget.onDarkModeChanged,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 600 ? 12.0 : 24.0;
            final maxContentWidth = constraints.maxWidth >= 1200
                ? 1160.0
                : 920.0;

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
                  width: maxContentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _GuardrailCard(),
                      const SizedBox(height: 16),
                      Text(
                        'Professional reference set',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'These supplied-illustration references are comparison '
                        'assets only. They are not the M1.5 canonical Twin.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      _CandidateGrid(candidates: _curatedCandidates),
                      const SizedBox(height: 20),
                      _LearnerSizePreview(
                        compactCandidate: _curatedCandidates[0],
                        heroCandidate: _curatedCandidates[3],
                      ),
                      if (widget.showAuthoringLane) ...[
                        const SizedBox(height: 20),
                        _buildAuthoringLane(context),
                      ],
                      if (_makerCandidates.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _CapturedCandidateSection(
                          candidates: _makerCandidates,
                          onCopySvg: (candidate) => _copyCandidatePayload(
                            '${candidate.label} SVG',
                            candidate.svg,
                          ),
                          onCopyJson: (candidate) => _copyCandidatePayload(
                            '${candidate.label} JSON',
                            candidate.json,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const _StopBoundaryCard(),
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

  Widget _buildAuthoringLane(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Candidate authoring lane',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'avatar_maker stays authoring-only. Capture as many in-memory '
              'candidates as needed, then compare them below.',
            ),
            const SizedBox(height: 16),
            Center(
              child: AvatarMakerAvatar(
                radius: 84,
                controller: controller,
                usePreview: true,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, customizerConstraints) {
                return AvatarMakerCustomizer(
                  scaffoldWidth: customizerConstraints.maxWidth,
                  scaffoldHeight: 450,
                  autosave: false,
                  controller: controller,
                  onChange: (_) {},
                );
              },
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final isReady = controller.displayedAvatarSVG.isNotEmpty;
                return FilledButton.icon(
                  onPressed: isReady ? _captureMakerCandidate : null,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Capture in-memory candidate'),
                );
              },
            ),
            if (_captureError != null) ...[
              const SizedBox(height: 8),
              Text(
                _captureError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuardrailCard extends StatelessWidget {
  const _GuardrailCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'M1 isolation contract',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No Firebase · no learner storage · no production navigation · '
              'no audio/voice · no canonical freeze. M0 remains untouched.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateGrid extends StatelessWidget {
  const _CandidateGrid({required this.candidates});

  final List<TwinIdentityCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final candidate in candidates)
              SizedBox(
                width: width,
                child: _CandidateCard(candidate: candidate),
              ),
          ],
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final TwinIdentityCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              image: true,
              label: '${candidate.label} candidate preview',
              child: SizedBox(
                height: 190,
                child: _CandidatePicture(candidate: candidate),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              candidate.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(candidate.intent, style: theme.textTheme.bodySmall),
            if (candidate.rasterBackedSvg) ...[
              const SizedBox(height: 6),
              Text(
                'Reference SVG · raster-backed · non-canonical',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidatePicture extends StatelessWidget {
  const _CandidatePicture({required this.candidate});

  final TwinIdentityCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final assetPath = candidate.assetPath;
    if (assetPath != null) {
      return SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        semanticsLabel: candidate.label,
      );
    }

    return SvgPicture.string(
      candidate.svg!,
      fit: BoxFit.contain,
      semanticsLabel: candidate.label,
    );
  }
}

class _LearnerSizePreview extends StatelessWidget {
  const _LearnerSizePreview({
    required this.compactCandidate,
    required this.heroCandidate,
  });

  static const _sizes = <double>[40, 48, 56, 72, 120];

  final TwinIdentityCandidate compactCandidate;
  final TwinIdentityCandidate heroCandidate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lightScheme = ColorScheme.fromSeed(
      seedColor: theme.colorScheme.primary,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: theme.colorScheme.primary,
      brightness: Brightness.dark,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Real learner-size check',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Compact learner sizes use the neutral reference as an upper-body '
              'crop so the face remains readable. The 120 px check keeps the '
              'full-body hero reference. This is a visual QA surface, not a '
              'runtime integration.',
            ),
            const SizedBox(height: 14),
            _PreviewSurface(
              label: 'Light surface',
              background: lightScheme.surface,
              foreground: lightScheme.onSurface,
              compactCandidate: compactCandidate,
              heroCandidate: heroCandidate,
            ),
            const SizedBox(height: 12),
            _PreviewSurface(
              label: 'Dark surface',
              background: darkScheme.surface,
              foreground: darkScheme.onSurface,
              compactCandidate: compactCandidate,
              heroCandidate: heroCandidate,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    required this.label,
    required this.background,
    required this.foreground,
    required this.compactCandidate,
    required this.heroCandidate,
  });

  final String label;
  final Color background;
  final Color foreground;
  final TwinIdentityCandidate compactCandidate;
  final TwinIdentityCandidate heroCandidate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: foreground)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final size in _LearnerSizePreview._sizes)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: size,
                        height: size,
                        child: size >= 120
                            ? _CandidatePicture(candidate: heroCandidate)
                            : _CompactUpperBodyPreview(
                                candidate: compactCandidate,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${size.toInt()} px',
                        style: TextStyle(color: foreground, fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactUpperBodyPreview extends StatelessWidget {
  const _CompactUpperBodyPreview({required this.candidate});

  final TwinIdentityCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.scale(
        scale: 1.75,
        alignment: Alignment.topCenter,
        child: _CandidatePicture(candidate: candidate),
      ),
    );
  }
}

class _CapturedCandidateSection extends StatelessWidget {
  const _CapturedCandidateSection({
    required this.candidates,
    required this.onCopySvg,
    required this.onCopyJson,
  });

  final List<TwinIdentityCandidate> candidates;
  final ValueChanged<TwinIdentityCandidate> onCopySvg;
  final ValueChanged<TwinIdentityCandidate> onCopyJson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Captured maker candidates',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${candidates.length} candidate(s), memory only.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final candidate in candidates) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: _CandidatePicture(candidate: candidate),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidate.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => onCopySvg(candidate),
                              icon: const Icon(Icons.copy_outlined),
                              label: const Text('Copy SVG'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => onCopyJson(candidate),
                              icon: const Icon(Icons.copy_outlined),
                              label: const Text('Copy JSON'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _StopBoundaryCard extends StatelessWidget {
  const _StopBoundaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Intentional stop boundary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'M1.1–M1.3 are prepared here. M1.4 requires explicit human '
              'approval of one identity before M1.5 may freeze canonical SVG, '
              'JSON and manifest assets. This studio cannot perform that freeze.',
            ),
          ],
        ),
      ),
    );
  }
}
