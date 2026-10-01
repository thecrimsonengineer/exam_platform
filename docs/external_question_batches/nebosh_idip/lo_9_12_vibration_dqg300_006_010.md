# NEBOSH IDip LO 9.12 Vibration — DQG300 Candidate Batch 006–010

**Content family:** NEBOSH International Diploma  
**Learning outcome:** 9.12 Vibration  
**Question standard:** DQG300 / DQ6 candidate  
**Lifecycle:** AUTHORING CANDIDATE  
**Publication target:** External NEBOSH content only. This batch must not be inserted into the CSP11 learner catalogue.  
**Governance reference:** CSP11 DQG300 validator/freeze-candidate standard is used as the authoring quality benchmark.

> This file contains authored question content and semantic review notes. It is deliberately isolated from the CSP11 production question catalogue. Formal publication through the application requires a NEBOSH-specific catalogue plus per-question structured DQG300 evidence.

---

## DQG300-VIB-006 — HAV trigger time and EAV

**Type:** `scenario_mcq`  
**Difficulty:** DQ6 candidate  
**Cognition:** Analysis / calculation  
**Tags:** `vibration`, `HAV`, `A8`, `EAV`, `trigger-time`, `LO9.12`

### Scenario

A maintenance technician uses a needle scaler with a representative hand-arm vibration magnitude of **7 m/s²**. Time records show **80 minutes of actual trigger time per shift**. The supervisor argues that the exposure is acceptable because the tool is used for less than two hours each day.

### Question

Which interpretation of the technician's exposure is BEST?

A. Treat 80 minutes as 80/480 of the measured magnitude, giving about 1.2 m/s² A(8), so the exposure remains below the action value.

B. Treat any daily trigger time below two hours as below the action value because the 7 m/s² magnitude is not sustained for most of the shift.

C. Calculate A(8) from magnitude and trigger time; 80 minutes gives about 2.9 m/s² A(8), so the action value has been exceeded.

D. Compare the measured 7 m/s² directly with the 5 m/s² daily limit and classify the worker as above the limit regardless of exposure duration.

**BEST answer:** C

### Rationale

For a single source:

`A(8) = a_hv × sqrt(T / 8 h)`

For 7 m/s² over 80 minutes:

`A(8) = 7 × sqrt(80 / 480) ≈ 2.86 m/s²`

The daily exposure action value is 2.5 m/s² A(8), so the worker is above the action value. The trigger time required to reach 2.5 m/s² at 7 m/s² is approximately 61 minutes. The supervisor's two-hour shortcut therefore fails.

### DQ6 distractor audit

- **A — D-METHOD / LINEAR-TIME SCALING:** Uses the correct variables but applies a linear time fraction instead of the square-root time relationship. It becomes defensible only if the exposure metric itself were defined as a linear time-weighted quantity.
- **B — D-THRESHOLD:** Correctly focuses on duration but invents a universal two-hour threshold. It becomes defensible only for a vibration magnitude whose calculated EAV trigger time is two hours.
- **D — D-MEASURE:** Correctly recognises the 5 m/s² ELV but compares instantaneous/representative magnitude directly with the daily A(8) limit. It becomes defensible only if the stated 7 m/s² were already an A(8) value.

**Key superiority:** C is the only option that uses both representative magnitude and actual trigger time with the correct A(8) relationship.

**References:** HSE, *Hand-arm vibration at work*; HSE, *Hand-arm vibration exposure calculator and ready-reckoner*; HSE L140, *Hand-arm vibration*.

---

## DQG300-VIB-007 — Representativeness of manufacturer vibration data

**Type:** `scenario_mcq`  
**Difficulty:** DQ6 candidate  
**Cognition:** Evaluation / analysis  
**Tags:** `vibration`, `HAV`, `measurement`, `manufacturer-data`, `risk-assessment`, `LO9.12`

### Scenario

A fabrication company buys several grinders whose manufacturer-declared vibration value is **4.5 m/s²**. In use, workers fit different discs, grind several materials, apply varying feed forces, and sometimes use tools with worn bearings. Management proposes using the declared value as the exact vibration magnitude for every task without checking whether it represents workplace use.

### Question

Which approach is BEST for the vibration risk assessment?

A. Use 4.5 m/s² as the definitive workplace magnitude because a declared manufacturer value remains valid for all normal uses of the same model.

B. Use the declared value as an initial information source, but establish whether it represents actual tasks and obtain better real-use data or measurement where uncertainty could change the risk decision.

C. Apply a fixed safety multiplier to every declared value and use the resulting figure as the workplace magnitude without considering discs, materials, condition, or work technique.

D. Disregard manufacturer information entirely and require instrument measurement of every individual worker and every tool before any vibration risk controls can be selected.

**BEST answer:** B

### Rationale

Manufacturer information can be useful for screening, equipment selection and initial estimation, but workplace exposure depends on how the equipment is actually used. Tool condition, accessory selection, material, operating technique and task duration can materially alter real exposure. Where uncertainty could affect whether action is required, the assessment should use data representative of the actual work, including appropriate measurement where necessary.

### DQ6 distractor audit

- **A — D-ASSUME:** Uses legitimate manufacturer data but assumes declared emission is automatically representative of every workplace condition. It becomes defensible if verified workplace use closely matches the conditions represented by the supplied data.
- **C — D-METHOD:** Correctly recognises uncertainty and conservatism but substitutes an arbitrary universal multiplier for task-specific representativeness. It becomes defensible only where an authoritative method prescribes that adjustment for the relevant data set.
- **D — D-OVER:** Correctly values workplace measurement but makes it a universal prerequisite and discards useful existing evidence. It becomes defensible where available information is inadequate and measurement is necessary to resolve the exposure decision.

**Key superiority:** B preserves the legitimate value of manufacturer information while requiring evidence that the estimate represents the actual exposure conditions.

**References:** HSE, *Hand-arm vibration: Measurement and monitoring*; HSE L140, *Hand-arm vibration*.

---

## DQG300-VIB-008 — WBV with shocks and jolts

**Type:** `scenario_mcq`  
**Difficulty:** DQ6 candidate  
**Cognition:** Analysis / evaluation  
**Tags:** `vibration`, `WBV`, `A8`, `VDV`, `shock`, `LO9.12`

### Scenario

A quarry excavator operator has a measured whole-body vibration A(8) below the relevant exposure action value. The measurement record also shows repeated severe jolts when the machine crosses damaged sections of the haul route. Several events cause the operator to lift from the seat momentarily. Management concludes that the low A(8) result proves the WBV risk is adequately controlled.

### Question

Which assessment response is BEST?

A. Accept the A(8) result as sufficient because daily RMS exposure already incorporates every relevant effect of intermittent shocks and jolts.

B. Retain A(8) for the continuous exposure assessment but also assess the shock-dominated exposure, using VDV where appropriate, and review route, speed, vehicle and seat controls.

C. Replace the A(8) assessment with the highest instantaneous acceleration recorded and compare that peak directly with the hand-arm vibration exposure limit value.

D. Double the measured A(8) whenever seat lift-off occurs and compare the adjusted value with the whole-body vibration action value as a conservative shock correction.

**BEST answer:** B

### Rationale

A(8) is useful for daily WBV exposure, but shock- and jolt-dominated exposures may require additional consideration because an RMS-based A(8) can under-represent the significance of repeated high shocks. Vibration dose value (VDV) is more sensitive to peaks and may be more appropriate for such exposure patterns. The assessment should also drive controls at the source and transmission path, including route condition, vehicle condition, speed and seat adjustment.

### DQ6 distractor audit

- **A — D-SCOPE:** Correctly uses A(8) for daily WBV but treats it as complete for a shock-heavy exposure pattern. It becomes defensible where significant shocks and jolts are absent.
- **C — D-MEASURE:** Correctly recognises the importance of high acceleration events but uses the wrong metric and the HAV limit for a WBV problem. It becomes defensible only if the question concerned the relevant hand-transmitted A(8) exposure rather than seat-transmitted WBV.
- **D — D-METHOD:** Correctly seeks a conservative correction but invents an unsupported doubling rule. It becomes defensible only if a validated assessment method explicitly required that correction under the stated conditions.

**Key superiority:** B is the only option that preserves the valid A(8) assessment while adding a metric and control review suited to shock-dominated WBV.

**References:** HSE L141, *Whole-body vibration*; HSE, *Vibration at work*.

---

## DQG300-VIB-009 — Lower tool vibration versus shorter exposure duration

**Type:** `scenario_mcq`  
**Difficulty:** DQ6 candidate  
**Cognition:** Analysis / calculation  
**Tags:** `vibration`, `HAV`, `tool-selection`, `A8`, `exposure-duration`, `LO9.12`

### Scenario

A contractor compares two breakers for one standard daily task. Representative in-use data show:

- **Breaker A:** 7 m/s² and completes the task in 45 minutes of trigger time.
- **Breaker B:** 5 m/s² and completes the same task in 120 minutes of trigger time.

Both tools are otherwise suitable for the job. The purchasing manager wants Breaker B because its vibration magnitude is lower.

### Question

Which interpretation is BEST?

A. Select Breaker B because the lower vibration magnitude necessarily produces the lower daily A(8) when both tools perform the same task.

B. Select Breaker A solely because its 45-minute trigger time is shorter, without considering its higher vibration magnitude in the daily exposure calculation.

C. Compare daily exposure rather than magnitude alone; Breaker A is about 2.1 m/s² A(8) and Breaker B about 2.5 m/s² A(8), so the lower-magnitude tool does not reduce exposure for this task.

D. Average each tool's vibration magnitude with its trigger time to create a combined selection score, then choose whichever tool has the lower numerical result.

**BEST answer:** C

### Rationale

Daily exposure depends on both vibration magnitude and actual trigger time:

`Breaker A = 7 × sqrt(0.75 / 8) ≈ 2.14 m/s² A(8)`

`Breaker B = 5 × sqrt(2 / 8) = 2.50 m/s² A(8)`

A lower-vibration tool can therefore fail to reduce daily exposure if it substantially increases exposure duration. Tool selection should consider suitability, productivity and representative daily exposure, not vibration magnitude in isolation.

### DQ6 distractor audit

- **A — D-PARTIAL:** Correctly prioritises lower-vibration equipment but omits the increased trigger time. It becomes correct if both tools require equal exposure duration.
- **B — D-PARTIAL:** Correctly recognises duration as decisive but ignores the higher acceleration magnitude. It becomes defensible if the vibration magnitudes are equal.
- **D — D-METHOD:** Correctly attempts to integrate magnitude and duration but combines unlike quantities with an invalid arithmetic method. It becomes defensible only if a validated selection index defines that calculation.

**Key superiority:** C is the only option that integrates both variables using the correct daily exposure relationship before making the equipment-selection judgement.

**References:** HSE, *Hand-arm vibration exposure calculator and ready-reckoner*; HSE L140, *Hand-arm vibration*.

---

## DQG300-VIB-010 — Symptoms when estimated A(8) is below the EAV

**Type:** `scenario_mcq`  
**Difficulty:** DQ6 candidate  
**Cognition:** Evaluation / application  
**Tags:** `vibration`, `HAVS`, `health-surveillance`, `EAV`, `risk-assessment`, `LO9.12`

### Scenario

After engineering improvements, a maintenance worker's current estimated HAV exposure is **2.2 m/s² A(8)**. During a periodic health questionnaire the worker reports persistent tingling and intermittent numbness in several fingers after vibrating-tool work. The supervisor proposes taking no further action because the estimate is below the 2.5 m/s² exposure action value.

### Question

Which response is BEST?

A. Take no further action unless exposure exceeds 2.5 m/s² A(8), because the action value is the boundary below which vibration-related ill health is excluded.

B. Refer the worker through the health-surveillance process and review exposure estimates and controls, because symptoms can indicate risk even when the current A(8) estimate is below the action value.

C. Maintain the existing controls until a clinician confirms HAVS, then reassess exposure only if the diagnosis establishes that the worker has a vibration-related disorder.

D. Increase the estimated A(8) to the action value for record purposes whenever symptoms are reported, then manage the case as though the numerical threshold had been exceeded.

**BEST answer:** B

### Rationale

The exposure action value is a legal/action trigger, not a line below which individual risk becomes impossible. Reported neurological symptoms warrant competent health-surveillance follow-up and should prompt a review of the worker's exposure history, current exposure estimate and control effectiveness. Health-surveillance findings are also useful feedback on whether the risk assessment and controls remain adequate.

### DQ6 distractor audit

- **A — D-THRESHOLD:** Correctly recognises the role of the EAV but treats it as a no-risk boundary. It becomes defensible only if the statement were limited to the numerical trigger itself rather than the overall health-risk decision.
- **C — D-TIME:** Correctly values clinical confirmation but delays exposure review until after diagnosis. It becomes defensible if there are no relevant symptoms or other indications of vibration risk requiring earlier review.
- **D — D-METHOD:** Correctly treats symptoms as important but falsifies the exposure metric instead of recording health evidence separately. It becomes defensible only if a formal method explicitly required a validated adjustment to the exposure estimate based on new measurement evidence.

**Key superiority:** B integrates the health-surveillance signal with exposure reassessment without misusing the EAV or altering the measured/estimated exposure value.

**References:** HSE L140, *Hand-arm vibration*; HSE, *Hand-arm vibration at work*; HSE enforcement guidance on hand-arm vibration.

---

## Batch semantic review summary

| Question | Primary decision | Distinct distractor failure modes | Numeric | Key position |
|---|---|---|---:|---:|
| VIB-006 | Trigger time / EAV | D-METHOD, D-THRESHOLD, D-MEASURE | Yes | C |
| VIB-007 | Data representativeness | D-ASSUME, D-METHOD, D-OVER | No | B |
| VIB-008 | Shock-heavy WBV | D-SCOPE, D-MEASURE, D-METHOD | No | B |
| VIB-009 | Tool selection and A(8) | D-PARTIAL, D-PARTIAL, D-METHOD | Yes | C |
| VIB-010 | Symptoms below EAV | D-THRESHOLD, D-TIME, D-METHOD | No | B |

### Authoring checks completed

- Exactly four options per question.
- Exactly one intended BEST answer per question.
- Scenario-dependent application/analysis rather than recall-only testing.
- At least two decisive scenario facts per question.
- Distractors remain within the same technical answer universe.
- Each distractor has an identified fatal flaw and a minimal counterfactual.
- Numerical distractors originate from identifiable reasoning pathways.
- No intentional absurd/filler option.
- Sources are authoritative HSE vibration guidance.

### Publication boundary

These are **DQG300 authoring candidates**, not a claim of formal DQG300 publication PASS. The repository's strict publication validator requires a separate structured evidence object containing all 299 atomic DQG records per question. Because this repository currently has no NEBOSH-specific learner catalogue/evidence pipeline, the batch is intentionally isolated from CSP11 production content rather than bypassing that requirement.
