# CSP11 ML × LTAM Integration

Status: CLOSED

Working branch: `phase-ml-ltam-integration`

## Source checkpoints

Micro-Learning runtime source:

```text
phase-ml13-animation-choreography-closed
d49950184ae38803f4a55e0e033e7c048e3f9c27
```

LTAM planning source:

```text
phase-learning-twin-motion-avatar
992adf804133f31a4e56325adfdb4e8ae90ba1e2
```

Common historical base:

```text
acf87f6a67a923f2dcc9b70485cfac2f56962050
```

The LTAM source is a frozen planning stream. Its six commits add documentation only. It does not yet contain the LTAM-4 motion mapper/manifest/controller/renderer or the LTAM-5 production motion pilot implementation.

Therefore this integration must not claim animated Learning Twin support that does not exist.

## Integration objective

Connect the completed ML startup MicroFact runtime to the existing Learning Twin visual identity while preserving both architecture boundaries:

```text
ML
published MicroFact
      ↓
ML-10 local repository
      ↓
ML-11 deterministic selector
      ↓
ML-12 startup payload
      ↓
ML-13 startup choreography
      ↓
ML × LTAM presentation bridge
      ↓
existing LearningTwinAvatar
      ↓
static SVG fallback today
      ↓
future LTAM motion renderer after LTAM-4/5 implementation
```

## Ownership boundary

### ML owns

- MicroFact wording;
- authority/provenance;
- curriculum mapping;
- publication state;
- startup eligibility;
- local repository;
- deterministic selection;
- assessment leakage blocking;
- MicroFact timing and startup choreography.

### LTAM / Learning Twin owns

- Learning Twin visual identity;
- avatar assets;
- future visual motion vocabulary;
- future motion manifest;
- future presentation mapper;
- future animation policy/controller/renderer;
- static SVG fallback.

### Forbidden coupling

The integration must not:

- make Learning Twin decide which MicroFact is shown;
- make MicroFact code alter Learning Twin learner-state decisions;
- add Lottie paths to ML domain models;
- put MicroFact text into Learning Twin domain messages;
- create a second avatar widget family;
- share animation controllers between startup motion and future Learning Twin motion;
- add network reads;
- add persistence;
- reopen or modify the 120 published MicroFacts.

## Imported LTAM contracts

The six LTAM planning documents are imported byte-for-byte from the planning branch into this integration branch so later implementation work can proceed from the newest ML runtime baseline without merging the obsolete LTAM snapshot.

Imported contracts:

- `LEARNING_TWIN_GLAXNIMATE_LOTTIE_AVATAR_FREEZE.md`
- `LTAM_1C_ANIMATION_LAYER_PREPARATION_AND_RIG_ARCHITECTURE.md`
- `LTAM_2_GLAXNIMATE_IDLE_MOTION_PROOF.md`
- `LTAM_3_LEARNING_TWIN_MOTION_STATE_LIBRARY.md`
- `LTAM_4_MOTION_MANIFEST_STATE_MAPPER_FLUTTER_RENDERER_FOUNDATION.md`
- `LTAM_5_BACKWARD_COMPATIBLE_AVATAR_UPGRADE_AND_CONTROLLED_RUNTIME_PILOT.md`

## Runtime bridge

New presentation bridge:

```text
lib/features/learning_twin/integration/
  micro_learning_twin_presentation.dart
```

The bridge accepts a validated/published `MicroFact` and produces only presentation metadata:

- `LearningTwinAsset.explain`;
- stable future motion event key:
  `microfact:<microFactId>:v<contentVersion>`;
- semantic presentation label.

The bridge does not inspect learner scores, readiness, progress, auth state, network state, assessment results, or Learning Twin session state.

## First integrated surface

The ML startup MicroFact card now renders the existing canonical:

```text
LearningTwinAvatar
```

instead of the generic lightbulb icon.

Current behavior remains static SVG because LTAM motion infrastructure is not implemented yet.

This is intentional and matches the LTAM frozen compatibility rule:

```text
no motion state
      ↓
existing SVG renderer
```

## Future motion seam

When LTAM-4/5 are implemented later, the integration seam is already prepared:

```text
MicroFact
  ↓
stable event key
  ↓
presentation bridge
  ↓
LearningTwinAvatar
  ↓
optional motionState
  ↓
LTAM MotionPolicy / Renderer
```

ML does not need to know Lottie filenames, loop rules, frame rates, or fallback paths.

## Integration gates

The integration is valid only when:

- ML-13 exact closed SHA is the branch base;
- all six frozen LTAM planning documents are present;
- 120 production MicroFact files are unchanged;
- Learning Twin domain files are unchanged;
- LearningTwinAvatar remains the canonical avatar widget;
- existing Learning Twin UI tests pass;
- ML-10 through ML-13 regressions pass;
- startup timing remains unchanged;
- bridge tests pass;
- startup MicroFact card renders LearningTwinAvatar;
- no network/persistence dependency is introduced.

## Next implementation sequence

```text
INT-0  Source checkpoint + architecture freeze
INT-1  Import LTAM frozen contracts
INT-2  MicroFact → Learning Twin presentation bridge
INT-3  Startup MicroFact card visual integration
INT-4  Cross-stream regression + freeze
```

Only after this integration checkpoint closes should actual LTAM-4/5 motion implementation begin on top of the integrated ML baseline.


## Integration closure

- Normalized integrated implementation SHA: `dc18c561253a221acfb6f09fc211e76efb2f2abe`.
- Cross-stream validation run: `35955880471` — PASS.
- ML production MicroFact files changed: 0.
- Learning Twin domain files changed: 0.
- The startup MicroFact card now renders the canonical `LearningTwinAvatar`.
- Current integrated avatar mode is static SVG fallback.
- A stable future motion event key is available as `microfact:<microFactId>:v<contentVersion>`.
- LTAM motion is intentionally **not enabled** because LTAM-4/5 remain frozen implementation plans rather than implemented runtime phases.
- The first animated LTAM production pilot remains `LearningTwinHero`, as required by the LTAM-5 contract.
- MicroFact surfaces must stay static until that controlled LTAM motion pilot closes.
