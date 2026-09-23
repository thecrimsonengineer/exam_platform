import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../features/lab/lab_runtime_binding.dart';
import 'lab_scenario_briefing_screen.dart';
import 'lab_scenario_catalog.dart';

class LabLibraryScreen extends StatefulWidget {
  const LabLibraryScreen({super.key})
    : persistent = false,
      runtimeBinding = null;

  const LabLibraryScreen.persistent({super.key})
    : persistent = true,
      runtimeBinding = null;

  const LabLibraryScreen.withBinding({super.key, required this.runtimeBinding})
    : persistent = true;

  final bool persistent;
  final LabLearnerRuntimeBinding? runtimeBinding;

  @override
  State<LabLibraryScreen> createState() => _LabLibraryScreenState();
}

class _LabLibraryScreenState extends State<LabLibraryScreen> {
  LabLearnerRuntimeBinding? _binding;
  List<LabScenarioDefinition> _scenarios = const <LabScenarioDefinition>[];
  bool _loading = false;
  String? _loadError;
  String? _openingIdentity;

  @override
  void initState() {
    super.initState();

    if (!widget.persistent) {
      _scenarios = LabScenarioCatalog.all;
      return;
    }

    _binding = widget.runtimeBinding ?? LabLearnerRuntimeBinding.firestore();
    _loadPersistentCatalogue();
  }

  Future<void> _loadPersistentCatalogue() async {
    final binding = _binding;
    if (binding == null) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final entries = await binding.listAvailable();
      final scenarios = entries
          .map(LabScenarioDefinition.fromCatalogueEntry)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _scenarios = scenarios;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _openScenario(LabScenarioDefinition scenario) async {
    final binding = _binding;
    final versionId = scenario.versionId;

    if (binding == null || versionId == null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LabScenarioBriefingScreen(scenario: scenario),
        ),
      );
      return;
    }

    final identity = scenario.id + '@' + versionId;
    setState(() => _openingIdentity = identity);

    try {
      final delivery = await binding.load(
        labId: scenario.id,
        versionId: versionId,
      );
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LabScenarioBriefingScreen(
            scenario: scenario,
            publishedPackage: delivery.package,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open this LAB. ' + error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _openingIdentity = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);
    final primary = Theme.of(context).colorScheme.primary;

    return StudentGlassScaffold(
      backgroundColor: dark ? const Color(0xFF0A111D) : const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Safety Decision LAB',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('lab-library-scroll'),
          padding: const EdgeInsets.all(20),
          children: [
            StudentGlassSurface(
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_rounded, size: 40, color: primary),
                  const SizedBox(height: 13),
                  Text(
                    'Practice safety decisions before they happen for real',
                    key: const ValueKey('lab-learner-intro'),
                    style: TextStyle(
                      color: text,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Choose a workplace scenario, make decisions and see how the '
                    'situation develops because of your choices.',
                    style: TextStyle(color: muted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Available scenarios',
              key: const ValueKey('lab-available-scenarios-heading'),
              style: TextStyle(
                color: text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a scenario to read the briefing and begin.',
              style: TextStyle(color: muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              StudentGlassSurface(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAB catalogue is unavailable.',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your connection and try again.',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('lab-catalogue-retry'),
                      onPressed: _loadPersistentCatalogue,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('RETRY'),
                    ),
                  ],
                ),
              )
            else if (_scenarios.isEmpty)
              StudentGlassSurface(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(18),
                child: Text(
                  'No Safety Decision LABs are available yet.',
                  key: const ValueKey('lab-catalogue-empty'),
                  style: TextStyle(color: muted, height: 1.4),
                ),
              )
            else
              for (final scenario in _scenarios) ...[
                _ScenarioCard(
                  scenario: scenario,
                  busy:
                      _openingIdentity ==
                      scenario.id + '@' + (scenario.versionId ?? ''),
                  onOpen: () => _openScenario(scenario),
                ),
                const SizedBox(height: 14),
              ],
            const SizedBox(height: 4),
            const _HowLabWorksCard(),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.onOpen,
    this.busy = false,
  });

  final LabScenarioDefinition scenario;
  final VoidCallback onOpen;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassSurface(
      key: ValueKey('lab-scenario-' + scenario.id),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                size: 31,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  scenario.title,
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(scenario.summary, style: TextStyle(color: muted, height: 1.45)),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final tag in scenario.focusTags)
                Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(tag),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(scenario.estimatedTime, style: TextStyle(color: muted)),
              const SizedBox(width: 18),
              Icon(Icons.alt_route_rounded, size: 18, color: muted),
              const SizedBox(width: 6),
              Text(scenario.decisionCountLabel, style: TextStyle(color: muted)),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: ValueKey('lab-scenario-open-' + scenario.id),
              onPressed: busy ? null : onOpen,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(busy ? 'OPENING...' : 'START SCENARIO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowLabWorksCard extends StatefulWidget {
  const _HowLabWorksCard();

  @override
  State<_HowLabWorksCard> createState() => _HowLabWorksCardState();
}

class _HowLabWorksCardState extends State<_HowLabWorksCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const ValueKey('lab-how-it-works-toggle'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How a LAB works',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Read, decide, confirm and see what happens next.',
                          style: TextStyle(color: muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 18),
            const _HowStep(
              number: '1',
              title: 'Read the situation',
              description: 'Understand what is happening around you.',
            ),
            const _HowStep(
              number: '2',
              title: 'Choose one action',
              description: 'Select the action you would take.',
            ),
            const _HowStep(
              number: '3',
              title: 'Confirm your decision',
              description:
                  'Once confirmed, that decision is locked for the current attempt.',
            ),
            const _HowStep(
              number: '4',
              title: 'See what happens next',
              description:
                  'Your decision creates a consequence and the scenario continues.',
            ),
            const Divider(height: 26),
            Text(
              'You can use Guided, Professional or Assessment mode after reading '
              'the scenario briefing. At the end, you can review your outcome '
              'and decision journey.',
              style: TextStyle(color: muted, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: muted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
