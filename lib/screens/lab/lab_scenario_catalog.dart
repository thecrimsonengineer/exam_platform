class LabScenarioDefinition {
  const LabScenarioDefinition({
    required this.id,
    required this.title,
    required this.summary,
    required this.focus,
    required this.difficulty,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String summary;
  final String focus;
  final String difficulty;
  final String assetPath;
}

abstract final class LabScenarioCatalog {
  static const confinedSpaceH2s = LabScenarioDefinition(
    id: 'confined_space_h2s_simops',
    title: 'Confined Space H2S SIMOPS Response',
    summary:
        'Manage a contractor confined-space job where permits, gas testing, '
        'changing SIMOPS and H2S conditions can change the outcome.',
    focus:
        'Permit control • Atmospheric testing • SIMOPS • H2S • Emergency response',
    difficulty: 'Professional safety judgement',
    assetPath: 'content/lab_reference_confined_space_h2s_v2.json',
  );

  static const all = <LabScenarioDefinition>[confinedSpaceH2s];
}
