class LabConsequencePresentation {
  const LabConsequencePresentation({
    required this.observable,
    required this.guidedInsight,
  });

  final String observable;
  final String guidedInsight;
}

class LabScenarioDefinition {
  const LabScenarioDefinition({
    required this.id,
    required this.title,
    required this.summary,
    required this.focusTags,
    required this.estimatedTime,
    required this.decisionCountLabel,
    required this.assetPath,
    required this.role,
    required this.situation,
    required this.objective,
    required this.peopleInvolved,
    required this.knownFacts,
    required this.consequences,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> focusTags;
  final String estimatedTime;
  final String decisionCountLabel;
  final String assetPath;
  final String role;
  final String situation;
  final String objective;
  final List<String> peopleInvolved;
  final List<String> knownFacts;
  final Map<String, LabConsequencePresentation> consequences;

  LabConsequencePresentation consequenceFor(String consequenceId) {
    return consequences[consequenceId] ??
        const LabConsequencePresentation(
          observable:
              'The scenario changes because of your confirmed decision.',
          guidedInsight:
              'Review what changed before making your next decision.',
        );
  }
}

abstract final class LabScenarioCatalog {
  static const confinedSpaceH2s = LabScenarioDefinition(
    id: 'confined_space_h2s_simops',
    title: 'Confined Space H2S SIMOPS Response',
    summary:
        'Manage a contractor confined-space job while permits, atmospheric '
        'conditions and nearby SIMOPS change around you.',
    focusTags: <String>[
      'Confined Space',
      'H2S',
      'SIMOPS',
      'Emergency Response',
    ],
    estimatedTime: '8–12 min',
    decisionCountLabel: '3–5 decisions',
    assetPath: 'content/lab_reference_confined_space_h2s_v2.json',
    role:
        'You are the site safety adviser supporting a contractor confined-space job.',
    situation:
        'A contractor crew is preparing to enter a process vessel. H2S may be '
        'present and nearby work can change the atmosphere.',
    objective:
        'Keep the entry controlled and respond safely as conditions change.',
    peopleInvolved: <String>[
      'Contractor supervisor',
      'Confined-space entrant',
      'Attendant',
      'Rescue team',
    ],
    knownFacts: <String>[
      'A confined-space permit is being used.',
      'Isolation must be verified before entry.',
      'Atmospheric conditions may change during nearby SIMOPS.',
      'A planned rescue capability is available.',
    ],
    consequences: <String, LabConsequencePresentation>{
      'permit_safe': LabConsequencePresentation(
        observable:
            'Entry remains on hold while the permit and isolation are checked. '
            'The crew has not entered the vessel.',
        guidedInsight:
            'Verifying the permit and isolation before entry keeps control in '
            'place before anyone is exposed.',
      ),
      'permit_defensible': LabConsequencePresentation(
        observable:
            'The permit is reviewed and the job remains controlled, but the '
            'existing isolation status is accepted without independent confirmation.',
        guidedInsight:
            'Reviewing the permit helps, but relying on an unverified isolation '
            'status can leave a control gap.',
      ),
      'permit_weak': LabConsequencePresentation(
        observable:
            'Preparations continue while the permit details are checked. Work '
            'activity and verification are now happening at the same time.',
        guidedInsight:
            'Allowing work preparations to continue can create pressure to move '
            'ahead before critical checks are complete.',
      ),
      'permit_critical': LabConsequencePresentation(
        observable:
            'Entry proceeds without independent permit and isolation verification. '
            'Conditions then deteriorate and an emergency response is required.',
        guidedInsight:
            'Assurance from another person does not replace verification of the '
            'controls required before confined-space entry.',
      ),
      'gas_safe': LabConsequencePresentation(
        observable:
            'Atmospheric testing is verified at the required locations and '
            'monitoring remains active as conditions change.',
        guidedInsight:
            'Current atmospheric information and continued monitoring help detect '
            'changes before they become an emergency.',
      ),
      'gas_defensible': LabConsequencePresentation(
        observable:
            'A fresh gas test is completed and monitoring is increased before the '
            'work continues.',
        guidedInsight:
            'Repeating the test improves the information available, especially '
            'when nearby activities can change the atmosphere.',
      ),
      'gas_weak': LabConsequencePresentation(
        observable:
            'The earlier gas test is relied on. No new verification is made while '
            'nearby conditions continue to change.',
        guidedInsight:
            'A previous test may not represent the atmosphere after conditions or '
            'nearby work have changed.',
      ),
      'gas_critical': LabConsequencePresentation(
        observable:
            'Work proceeds without another atmospheric test because ventilation '
            'is assumed to be sufficient. An emergency condition develops.',
        guidedInsight:
            'Ventilation does not remove the need to verify the atmosphere when '
            'hazardous gases may be present.',
      ),
      'simops_safe': LabConsequencePresentation(
        observable:
            'The entrant leaves the vessel, the permit is suspended and the '
            'conflicting activity is reassessed before any restart.',
        guidedInsight:
            'Responding to the rising trend before the alarm point protects the '
            'entrant while the changed conditions are investigated.',
      ),
      'simops_defensible': LabConsequencePresentation(
        observable:
            'The work is paused while the gas trend and nearby activity are '
            'checked. The situation stays controlled, but the entrant is not '
            'immediately withdrawn.',
        guidedInsight:
            'Pausing reduces exposure to change, though leaving the entrant in '
            'place can delay a more conservative response.',
      ),
      'simops_weak': LabConsequencePresentation(
        observable:
            'The task continues with more frequent gas checks. The rising trend '
            'remains present while the entrant stays in the space.',
        guidedInsight:
            'Waiting for an alarm threshold can miss the significance of a clear '
            'change in conditions.',
      ),
      'simops_critical': LabConsequencePresentation(
        observable:
            'Both activities continue despite the rising H2S trend. The situation '
            'escalates to an H2S emergency.',
        guidedInsight:
            'A valid permit does not make changed conditions safe. The work must '
            'remain controlled as the situation develops.',
      ),
      'emergency_recover': LabConsequencePresentation(
        observable:
            'The emergency plan is activated, unprotected entry is prevented and '
            'the planned rescue capability is used. The immediate situation is '
            'brought under control.',
        guidedInsight:
            'Planned rescue protects both the casualty and would-be rescuers from '
            'creating additional victims.',
      ),
      'emergency_contain': LabConsequencePresentation(
        observable:
            'The area is evacuated and isolated while rescue resources are '
            'mobilised. The situation is contained, but the response is slower.',
        guidedInsight:
            'Preventing spontaneous entry limits secondary exposure while the '
            'rescue response is organised.',
      ),
      'emergency_major': LabConsequencePresentation(
        observable:
            'A nearby worker approaches the opening before the rescue team controls '
            'the scene. The emergency escalates and secondary exposure becomes a concern.',
        guidedInsight:
            'Unprotected approach to a toxic atmosphere can turn one casualty into '
            'a larger emergency.',
      ),
      'emergency_fatal': LabConsequencePresentation(
        observable:
            'An unplanned rescue entry is made without protection. A secondary '
            'casualty occurs and the LAB reaches a critical outcome.',
        guidedInsight:
            'Confined-space rescue must not create another casualty through '
            'unprotected entry.',
      ),
      'close_safe': LabConsequencePresentation(
        observable:
            'The space remains closed while causes are investigated and corrective '
            'actions are verified before any restart.',
        guidedInsight:
            'A controlled closeout prevents the same failure from being carried '
            'straight into the next attempt.',
      ),
      'close_recovery': LabConsequencePresentation(
        observable:
            'The suspension remains in place while identified failures are corrected '
            'and a controlled restart review is completed.',
        guidedInsight:
            'Correcting known failures before restart reduces the chance of repeating '
            'the event.',
      ),
      'close_contained': LabConsequencePresentation(
        observable:
            'The event is recorded and the crew is re-briefed once the atmosphere '
            'is acceptable. The operation moves toward restart.',
        guidedInsight:
            'Atmospheric recovery alone may not address the causes that allowed the '
            'event to develop.',
      ),
      'close_major': LabConsequencePresentation(
        observable:
            'The task is restarted after ventilation clears the alarm even though '
            'the wider causes have not been resolved. The outcome becomes a major incident.',
        guidedInsight:
            'Restarting because of schedule pressure can reintroduce unresolved '
            'controls and repeat the failure.',
      ),
    },
  );

  static const all = <LabScenarioDefinition>[confinedSpaceH2s];
}
