import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AvatarMakerSpikeScreen extends StatefulWidget {
  const AvatarMakerSpikeScreen({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<AvatarMakerSpikeScreen> createState() => _AvatarMakerSpikeScreenState();
}

class _AvatarMakerSpikeScreenState extends State<AvatarMakerSpikeScreen> {
  late final NonPersistentAvatarMakerController _controller;

  String _jsonExport = '';
  String _svgExport = '';
  String? _exportError;

  @override
  void initState() {
    super.initState();
    _controller = NonPersistentAvatarMakerController(
      locale: const Locale('en'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _captureExports() {
    if (_controller.displayedAvatarSVG.isEmpty) {
      setState(() {
        _exportError = 'Avatar initialization is still completing.';
      });
      return;
    }

    try {
      final json = _controller.getJsonOptionsSync();
      final svg = _controller.getAvatarSVGSync();

      setState(() {
        _jsonExport = json;
        _svgExport = svg;
        _exportError = null;
      });
    } catch (error) {
      setState(() {
        _exportError = error.toString();
      });
    }
  }

  Future<void> _copyExport(String label, String value) async {
    if (value.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard.')));
  }

  String _preview(String value) {
    const maxLength = 220;
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase M0 · Learning Twin Spike'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dark_mode_outlined, size: 20),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onDarkModeChanged,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth < 600;
            final contentWidth = isPhone ? constraints.maxWidth : 760.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 12 : 24,
                vertical: 16,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ArchitectureNotice(theme: theme),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Disposable authoring avatar',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AvatarMakerAvatar(
                                radius: isPhone ? 74 : 92,
                                controller: _controller,
                                usePreview: true,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This is not yet the canonical Naveed Twin.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'avatar_maker 1.8.0 customizer',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, customizerConstraints) {
                                  return AvatarMakerCustomizer(
                                    scaffoldWidth:
                                        customizerConstraints.maxWidth,
                                    scaffoldHeight: isPhone ? 430 : 470,
                                    autosave: false,
                                    controller: _controller,
                                    onChange: (_) => _captureExports(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ExportPanel(
                        controller: _controller,
                        jsonExport: _jsonExport,
                        svgExport: _svgExport,
                        exportError: _exportError,
                        preview: _preview,
                        onCapture: _captureExports,
                        onCopyJson: () => _copyExport('JSON', _jsonExport),
                        onCopySvg: () => _copyExport('SVG', _svgExport),
                      ),
                      const SizedBox(height: 24),
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

class _ArchitectureNotice extends StatelessWidget {
  const _ArchitectureNotice({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'M0 isolation contract',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Non-persistent controller · no Firebase · no learner storage · '
              'no production navigation · no sound or voice integration.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportPanel extends StatelessWidget {
  const _ExportPanel({
    required this.controller,
    required this.jsonExport,
    required this.svgExport,
    required this.exportError,
    required this.preview,
    required this.onCapture,
    required this.onCopyJson,
    required this.onCopySvg,
  });

  final NonPersistentAvatarMakerController controller;
  final String jsonExport;
  final String svgExport;
  final String? exportError;
  final String Function(String value) preview;
  final VoidCallback onCapture;
  final VoidCallback onCopyJson;
  final VoidCallback onCopySvg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final controllerReady = controller.displayedAvatarSVG.isNotEmpty;
            final captured = jsonExport.isNotEmpty && svgExport.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Canonical-export proof',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controllerReady
                      ? 'Controller ready. SVG and JSON can be exported in memory.'
                      : 'Initializing non-persistent avatar controller…',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: controllerReady ? onCapture : null,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Capture SVG + JSON'),
                ),
                if (exportError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    exportError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                if (captured) ...[
                  const SizedBox(height: 16),
                  Text('JSON · ${jsonExport.length} characters'),
                  const SizedBox(height: 4),
                  SelectableText(preview(jsonExport)),
                  const SizedBox(height: 12),
                  Text('SVG · ${svgExport.length} characters'),
                  const SizedBox(height: 4),
                  SelectableText(preview(svgExport)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onCopyJson,
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy JSON'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onCopySvg,
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy SVG'),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
