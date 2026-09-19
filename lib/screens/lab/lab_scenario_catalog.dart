class LabConsequencePresentation {
  const LabConsequencePresentation({
    required this.observable,
    required this.guidedInsight,
  });

  final String observable;
  final String guidedInsight;
}

class LabLearnerStatusItem {
  const LabLearnerStatusItem({required this.label, required this.value});

  final String label;
  final String value;
}

class LabEvidencePresentation {
  const LabEvidencePresentation({
    required this.id,
    required this.title,
    required this.summary,
    required this.details,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> details;
}

class LabEndingPresentation {
  const LabEndingPresentation({
    required this.title,
    required this.narrative,
    required this.keyTurningPoint,
  });

  final String title;
  final String narrative;
  final String keyTurningPoint;
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
    required this.evidence,
    required this.decisionTitles,
    required this.endings,
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
  final Map<String, LabEvidencePresentation> evidence;
  final Map<String, String> decisionTitles;
  final Map<String, LabEndingPresentation> endings;
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

  LabEvidencePresentation? evidenceFor(String evidenceId) =>
      evidence[evidenceId];

  String decisionTitleFor(String nodeId) =>
      decisionTitles[nodeId] ?? 'Safety decision';

  LabEndingPresentation endingFor(String? endingId) {
    return endings[endingId] ??
        const LabEndingPresentation(
          title: 'Scenario complete',
          narrative:
              'Your decisions brought this authored scenario to an ending.',
          keyTurningPoint:
              'Review your decision journey to see where the situation changed.',
        );
  }

  List<LabLearnerStatusItem> learnerStatus(
    Map<String, Object?> stateValues,
    int simulatedMinutes,
  ) {
    String yesNo(Object? value, {required String yes, required String no}) =>
        value == true ? yes : no;

    return <LabLearnerStatusItem>[
      LabLearnerStatusItem(
        label: 'Permit',
        value: yesNo(
          stateValues['permit_verified'],
          yes: 'Verified',
          no: 'Not yet verified',
        ),
      ),
      LabLearnerStatusItem(
        label: 'Isolation',
        value: yesNo(
          stateValues['isolated'],
          yes: 'Verified',
          no: 'Not yet verified',
        ),
      ),
      LabLearnerStatusItem(
        label: 'Atmospheric test',
        value: yesNo(
          stateValues['gas_test_verified'],
          yes: 'Verified',
          no: 'Not yet verified',
        ),
      ),
      LabLearnerStatusItem(
        label: 'Rescue readiness',
        value: yesNo(
          stateValues['rescue_ready'],
          yes: 'Confirmed',
          no: 'Not yet confirmed',
        ),
      ),
      LabLearnerStatusItem(
        label: 'Scenario time',
        value: simulatedMinutes.toString() + ' min',
      ),
    ];
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
    evidence: <String, LabEvidencePresentation>{
      'permit': LabEvidencePresentation(
        id: 'permit',
        title: 'Confined-space permit',
        summary: 'The permit defines the authorised entry and required controls.',
        details: <String>[
          'Work scope: internal vessel inspection and maintenance.',
          'Entry requires verified isolation and atmospheric testing.',
          'The permit must be suspended if conditions or nearby work change.',
        ],
      ),
      'isolation_record': LabEvidencePresentation(
        id: 'isolation_record',
        title: 'Isolation record',
        summary: 'The isolation record shows the controls applied before entry.',
        details: <String>[
          'Relevant process connections are identified for isolation.',
          'Isolation status must be independently verified before entry.',
          'Any change affecting the isolation requires the job to be reassessed.',
        ],
      ),
      'gas_test': LabEvidencePresentation(
        id: 'gas_test',
        title: 'Atmospheric test',
        summary: 'Atmospheric testing provides the current condition of the space.',
        details: <String>[
          'Testing must represent the locations where entrants may be exposed.',
          'Conditions can change after the initial test.',
          'Continuous or repeated monitoring is needed when changing work can affect the atmosphere.',
        ],
      ),
      'rescue_plan': LabEvidencePresentation(
        id: 'rescue_plan',
        title: 'Rescue plan',
        summary: 'The plan defines how a confined-space emergency is managed.',
        details: <String>[
          'Unprotected spontaneous entry is not an acceptable rescue method.',
          'The planned rescue capability must be mobilised and controlled.',
          'The scene must be protected from secondary casualties.',
        ],
      ),
    },
    decisionTitles: <String, String>{
      'permit_decision': 'Permit and isolation',
      'gas_decision': 'Atmospheric testing',
      'simops_decision': 'Changing SIMOPS conditions',
      'emergency_decision': 'Emergency response',
      'closeout_decision': 'Recovery and closeout',
    },
    endings: <String, LabEndingPresentation>{
      'safe_completion': LabEndingPresentation(
        title: 'Safe completion',
        narrative:
            'The work remained controlled as conditions changed. The scenario '
            'ended without an uncontrolled confined-space emergency.',
        keyTurningPoint:
            'You acted on changing conditions before they developed into an emergency.',
      ),
      'controlled_recovery': LabEndingPresentation(
        title: 'Controlled recovery',
        narrative:
            'The situation required additional control and recovery actions, '
            'but the operation was brought back under control.',
        keyTurningPoint:
            'Recovery decisions prevented the earlier control weakness from escalating further.',
      ),
      'incident_contained': LabEndingPresentation(
        title: 'Incident contained',
        narrative:
            'The scenario developed into an incident condition, but later '
            'decisions prevented a more serious outcome.',
        keyTurningPoint:
            'The response after conditions deteriorated limited the consequences.',
      ),
      'major_incident': LabEndingPresentation(
        title: 'Major incident',
        narrative:
            'Unresolved control failures and later decisions allowed the event '
            'to develop into a major incident outcome.',
        keyTurningPoint:
            'Earlier warning signs or recovery opportunities were not fully controlled before restart.',
      ),
      'critical_failure': LabEndingPresentation(
        title: 'Critical failure',
        narrative:
            'The emergency response created an additional severe consequence '
            'and the scenario reached a critical ending.',
        keyTurningPoint:
            'An unprotected rescue response turned the original emergency into a secondary-casualty event.',
      ),
    },
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
