# CSP11 DQ6 Quality Gate — 300 Atomic DQG Contract

Status: Step 1 freeze candidate. This supersedes the 64-rule matrix for future implementation.

Source Git blob: `68b4fe0a132c8cc7ebd095aa7340a6ee4bb29b4b`

Format: `DQG-ID|Section|Atomic requirement`

DQG-001|S01|Exactly four options are required
DQG-002|S01|Exactly one option is the BEST answer
DQG-003|S01|Exactly three options are distractors
DQG-004|S01|Distractors may not be filler answers
DQG-005|S01|Every distractor is an expert-level near miss
DQG-006|S01|Expert near misses must be superficially defensible
DQG-007|S01|Exactly one answer remains defensible after complete technical and scenario analysis
DQG-008|S01|Difficulty may not depend on ambiguity, deceptive wording, obscure trivia, grammatical tricks, or missing information
DQG-009|S02|Question difficulty is exactly DQ6
DQG-010|S02|Distractor 1 plausibility is exactly 5/5
DQG-011|S02|Distractor 2 plausibility is exactly 5/5
DQG-012|S02|Distractor 3 plausibility is exactly 5/5
DQG-013|S02|Distractor 1 Truth Component Score is exactly 4/4
DQG-014|S02|Distractor 2 Truth Component Score is exactly 4/4
DQG-015|S02|Distractor 3 Truth Component Score is exactly 4/4
DQG-016|S02|DQS is exactly 100/100
DQG-017|S02|All BLOCK gates pass
DQG-018|S02|All mandatory FAIL gates pass
DQG-019|S02|All ambiguity checks pass
DQG-020|S02|All source-support checks pass
DQG-021|S02|All option-equivalence checks pass
DQG-022|S02|All BEST-answer superiority checks pass and no publication override exists
DQG-023|S03|All four options belong to the same technical answer universe
DQG-024|S03|All three distractors are credible to a well-prepared learner
DQG-025|S03|Each distractor is substantially correct except for one decisive technical defect
DQG-026|S03|At least two scenario facts or technical conditions are integrated
DQG-027|S03|Superficial keyword matching cannot reveal the answer
DQG-028|S03|Terminology familiarity alone cannot reveal the answer
DQG-029|S03|Grammar cannot enable elimination
DQG-030|S03|Option length cannot enable elimination
DQG-031|S03|Formatting, category mismatch, or absurdity cannot enable elimination
DQG-032|S03|Each distractor represents a sophisticated reasoning pathway
DQG-033|S03|Exactly one option satisfies every material stem requirement
DQG-034|S03|Qualified SME rejection proof exists and technical reasoning rather than test-taking technique is required
DQG-035|S04|Every distractor plausibility score equals 5
DQG-036|S04|Every distractor belongs to the correct technical domain
DQG-037|S04|Every distractor uses correct professional terminology
DQG-038|S04|Every distractor addresses the actual hazard, system, control, calculation, or decision
DQG-039|S04|Every distractor contains substantial technical truth
DQG-040|S04|Every distractor reflects an informed but incomplete reasoning pathway
DQG-041|S04|Every distractor differs from the BEST answer by a minute decisive defect
DQG-042|S04|Every distractor requires subject knowledge to eliminate and remains credible in professional practice
DQG-043|S05|Every distractor Truth Component Score equals 4
DQG-044|S05|Every distractor is almost completely technically correct
DQG-045|S05|Every distractor is invalid because of one decisive condition or limitation
DQG-046|S05|Assumption, priority, classification, timing, or causal-level defects are allowed only when decisive
DQG-047|S05|Calculation relationship, equipment specification, or scenario-fact defects are allowed only when decisive
DQG-048|S05|No distractor is generally false
DQG-049|S05|Weak obviously inferior distractors are prohibited
DQG-050|S05|Technical truth in a distractor must remain material rather than decorative
DQG-051|S06|Every distractor has one dominant fatal flaw
DQG-052|S06|Correct hazard recognition is preserved unless hazard recognition itself is the single fatal flaw
DQG-053|S06|Correct technical family is preserved unless family selection itself is the single fatal flaw
DQG-054|S06|Correct professional terminology is preserved
DQG-055|S06|Correct general objective is preserved
DQG-056|S06|Correct partial reasoning is preserved
DQG-057|S06|Several unrelated errors in one distractor are prohibited
DQG-058|S06|An expert near miss may fail one dependency or equivalent narrow condition but not multiple independent dimensions
DQG-059|S07|The three distractors fail for meaningfully different reasons
DQG-060|S07|Cosmetic wording differences do not count as reasoning diversity
DQG-061|S07|Each distractor has a unique misconception fingerprint
DQG-062|S07|No two distractors may be the same misconception expressed differently
DQG-063|S07|Distinct distractor families must correspond to distinct reasoning failures
DQG-064|S08|Every distractor metadata record contains role=expert_near_miss
DQG-065|S08|Every distractor metadata record contains difficultyLevel=DQ6
DQG-066|S08|Every distractor metadata record contains plausibilityScore=5
DQG-067|S08|Every distractor metadata record contains truthComponentScore=4
DQG-068|S08|Every distractor metadata record contains a family
DQG-069|S08|Every distractor metadata record contains targetedMisconception
DQG-070|S08|Every distractor metadata record contains whyTempting
DQG-071|S08|Every distractor metadata record contains fatalFlaw
DQG-072|S08|Every distractor metadata record contains non-empty scenarioEvidence
DQG-073|S08|Every distractor metadata record contains technicalTruth
DQG-074|S08|Every distractor metadata record contains keyDifference
DQG-075|S08|Every distractor metadata record contains counterfactualToBecomeCorrect
DQG-076|S08|Every distractor metadata record contains misconceptionFingerprint
DQG-077|S08|Missing any mandatory distractor metadata field blocks publication
DQG-078|S09|D-COND retains correct principle but wrong condition
DQG-079|S09|D-SCOPE represents incomplete problem coverage
DQG-080|S09|D-PRIORITY and D-HIER preserve validity but fail priority or hierarchy
DQG-081|S09|D-CAUSE and D-TIME fail causal level or timing
DQG-082|S09|D-METHOD and D-ASSUME fail method applicability or unsupported assumption
DQG-083|S09|D-PARTIAL, D-OVER, and D-UNDER preserve substantial truth while missing decisive completeness
DQG-084|S09|Technical/numerical families D-CLASS through D-RELIAB retain their defined neighboring-concept errors
DQG-085|S09|System-analysis families D-HUMAN, D-BARRIER, D-LOPA, D-FTA, and D-ETA retain their defined errors
DQG-086|S09|Custom distractor families are allowed only with explicit technical justification and must not bypass other gates
DQG-087|S10|Every DQ6 item integrates multiple pieces of information
DQG-088|S10|Scenario evidence includes at least two decisive facts or conditions
DQG-089|S10|Technical principle must be integrated with scenario facts
DQG-090|S10|Question command must participate in selecting the BEST answer
DQG-091|S10|Distractors should represent incomplete integration rather than random misconceptions
DQG-092|S10|KEY must integrate the complete decisive scenario set required by the item
DQG-093|S11|A criterion matrix exists before final validation
DQG-094|S11|Criterion matrix contains KEY and all three distractors
DQG-095|S11|All material criteria are represented in the matrix
DQG-096|S11|KEY satisfies 100 percent of material criteria
DQG-097|S11|Each distractor fails at least one decisive criterion
DQG-098|S11|Distractors remain otherwise highly credible despite the decisive failed criterion
DQG-099|S11|Criterion matrix has no missing option-to-criterion cells
DQG-100|S12|Specific KEY>D1 superiority proof exists
DQG-101|S12|Specific KEY>D2 superiority proof exists
DQG-102|S12|Specific KEY>D3 superiority proof exists
DQG-103|S12|Each superiority proof identifies the decisive technical or scenario distinction
DQG-104|S12|Generic statements such as less appropriate are rejected
DQG-105|S12|Superiority proof is consistent with the criterion matrix
DQG-106|S13|Every distractor has a counterfactual that would make it correct or defensible
DQG-107|S13|Each counterfactual is the smallest plausible scenario change
DQG-108|S13|Counterfactual does not require wholesale scenario rewriting
DQG-109|S13|Counterfactual remains in the same technical neighborhood as the original item
DQG-110|S14|KEY-to-D1 confusability equals exactly 4
DQG-111|S14|KEY-to-D2 confusability equals exactly 4
DQG-112|S14|KEY-to-D3 confusability equals exactly 4
DQG-113|S14|Confusability below 4 blocks as insufficiently close
DQG-114|S14|Confusability equal to 5 blocks as effective equivalence or ambiguity
DQG-115|S14|Only score 4 is acceptable for every KEY-distractor pair
DQG-116|S15|All options have comparable technical domain
DQG-117|S15|All options have comparable professional level
DQG-118|S15|All options have comparable grammatical structure
DQG-119|S15|All options have comparable specificity
DQG-120|S15|All options have comparable length
DQG-121|S15|All options have comparable terminology
DQG-122|S15|All options have comparable degree of detail
DQG-123|S15|All options have comparable units and numerical precision
DQG-124|S15|All options have comparable conditional wording
DQG-125|S16|Character count is measured for every option
DQG-126|S16|Word count is measured for every option
DQG-127|S16|Clause count is measured for every option
DQG-128|S16|Technical-term count is measured for every option
DQG-129|S16|Qualifier count is measured for every option
DQG-130|S16|KEY is not uniquely longer or uniquely shorter in a cueing manner
DQG-131|S16|No material option-length cue exists
DQG-132|S17|Equipment-type specificity is balanced when present
DQG-133|S17|Location or distance specificity is balanced when present
DQG-134|S17|Process-condition specificity is balanced when present
DQG-135|S17|Numerical-threshold specificity is balanced when present
DQG-136|S17|Technical-qualifier specificity is balanced when present
DQG-137|S17|KEY may not look like the only option written by a subject-matter expert
DQG-138|S18|Grammatical agreement may not identify the KEY
DQG-139|S18|Repeated wording may not identify the KEY
DQG-140|S18|Distinctive terminology may not identify the KEY
DQG-141|S18|Stem wording copied uniquely into the KEY is prohibited
DQG-142|S18|Different tense or voice may not identify the KEY
DQG-143|S18|Unusual capitalization may not identify the KEY
DQG-144|S18|Excessive precision unique to the KEY is prohibited
DQG-145|S18|Unique parenthetical explanation or qualification is prohibited
DQG-146|S18|No answer-position cue is permitted
DQG-147|S19|Lexical overlap between stem and every option is evaluated
DQG-148|S19|Excessive unique stem-to-KEY overlap blocks
DQG-149|S19|Technically unavoidable shared terminology is permitted only when comparably represented across distractors
DQG-150|S19|No keyword-based shortcut may identify the KEY
DQG-151|S20|Absolute or certainty language is explicitly inspected
DQG-152|S20|Words such as always, never, only, completely, guarantees, eliminates, and under all circumstances receive scrutiny
DQG-153|S20|Certainty wording that makes a distractor easy to eliminate blocks
DQG-154|S20|Necessary absolute wording is allowed only when it does not create an elimination shortcut
DQG-155|S21|No option is absurd
DQG-156|S21|No option is unrelated
DQG-157|S21|No option is grammatically different in a cueing way
DQG-158|S21|No option is much shorter or much longer in a cueing way
DQG-159|S21|No option belongs to a different technical category in a cueing way
DQG-160|S21|No numerical option is ridiculous enough for non-technical elimination
DQG-161|S21|No option is obviously unsafe merely to advertise itself as wrong
DQG-162|S21|No option is obviously overgeneralised
DQG-163|S21|Every elimination requires subject knowledge or scenario reasoning
DQG-164|S22|When technically appropriate at least one distractor is as sophisticated as or more sophisticated sounding than the KEY
DQG-165|S22|An advanced-sounding distractor remains wrong for one precise technical reason
DQG-166|S22|Advanced wording may not create a second defensible answer
DQG-167|S23|Every numerical distractor has a valid reasoning pathway
DQG-168|S23|Every numerical distractor records distractorCalculationPath
DQG-169|S23|Wrong-complement pathways are traceable when used
DQG-170|S23|AND/OR or series/parallel inversion pathways are traceable when used
DQG-171|S23|Incorrect denominator or event-frequency conversion pathways are traceable when used
DQG-172|S23|PFD/RRF or conditional-probability pathways are traceable when used
DQG-173|S23|Premature-rounding pathways are traceable when used
DQG-174|S23|Random numerical values without reasoning provenance are prohibited
DQG-175|S24|A factually true distractor may be used only when it answers the wrong requested level
DQG-176|S24|Immediate, contributing, underlying, and root-cause levels remain distinguishable
DQG-177|S24|Only one option answers the specific command level
DQG-178|S24|Wrong-level correctness is allowed only when the distinction is technically defensible
DQG-179|S24|Wrong-level distractor truth may not create ambiguity
DQG-180|S25|KEY requires no unstated assumption
DQG-181|S25|Reasonable but unsupported assumptions may be used only as distractor traps
DQG-182|S25|Every material assumption is documented
DQG-183|S25|assumptionUsed is recorded
DQG-184|S25|scenarioSupport is recorded
DQG-185|S25|Any unstated assumption that makes KEY and distractor equally valid blocks
DQG-186|S26|At least one authoritative or otherwise accepted source supports the tested distinction
DQG-187|S26|Recognised technical principles may support the distinction
DQG-188|S26|Published guidance, accepted calculations, applicable standards, or validated course sources may support the distinction
DQG-189|S26|Source support covers the KEY
DQG-190|S26|Source support covers every distractor-rejection distinction
DQG-191|S26|Unsupported microscopic distinctions block
DQG-192|S26|Source authority and applicability are verified
DQG-193|S27|No competent SME can reasonably defend a distractor as equally correct using only the stem
DQG-194|S27|Any equally defensible distractor blocks
DQG-195|S27|DQ6 difficulty may not be created by uncertainty about question meaning
DQG-196|S27|Ambiguity review is explicit and completed
DQG-197|S28|KEY satisfies the hazard condition
DQG-198|S28|KEY satisfies scope
DQG-199|S28|KEY satisfies timing
DQG-200|S28|KEY satisfies priority
DQG-201|S28|KEY satisfies mechanism
DQG-202|S28|KEY satisfies the technical principle
DQG-203|S28|KEY satisfies scenario conditions
DQG-204|S28|KEY satisfies the command word
DQG-205|S28|KEY satisfies calculation requirements when applicable
DQG-206|S28|KEY satisfies assumption requirements
DQG-207|S29|All three distractors are DQ6
DQG-208|S29|All three distractors have plausibility 5
DQG-209|S29|All three distractors have Truth Component Score 4
DQG-210|S29|All three distractors have confusability 4 with the KEY
DQG-211|S29|All three distractors have a unique fatal flaw
DQG-212|S29|All three distractors have unique misconception fingerprints
DQG-213|S29|All three distractors pass scenario anchoring, counterfactual validation, technical homogeneity, and elimination resistance
DQG-214|S29|No strongest-distractor-plus-two-weaker-distractors pattern is permitted
DQG-215|S30|DQS contains exactly ten fixed categories
DQG-216|S30|Plausibility category scores 10/10 only when all three distractors are 5
DQG-217|S30|Truth Component category scores 10/10 only when all three distractors are 4
DQG-218|S30|DQ6 compliance category scores 10/10 only on full DQ6 compliance
DQG-219|S30|Scenario integration category scores 10/10 only on full integration compliance
DQG-220|S30|Distinct misconception targeting category scores 10/10 only on full compliance
DQG-221|S30|Single-fatal-flaw category scores 10/10 only on full compliance
DQG-222|S30|Pairwise confusability category scores 10/10 only when all three equal 4
DQG-223|S30|Linguistic/length/specificity parity category scores 10/10 only on full compliance
DQG-224|S30|Elimination resistance category scores 10/10 only on full compliance
DQG-225|S30|BEST-answer superiority and ambiguity proof category scores 10/10 only on full compliance
DQG-226|S30|DQS is exactly 100 with no rounding or tolerance; 99 fails
DQG-227|S31|More than one defensible answer hard-blocks
DQG-228|S31|Any distractor plausibility below 5 hard-blocks
DQG-229|S31|Any distractor Truth Component Score below 4 hard-blocks
DQG-230|S31|Question below DQ6 hard-blocks
DQG-231|S31|DQS below 100 hard-blocks
DQG-232|S31|Semantic duplicate options hard-block
DQG-233|S31|Duplicate misconception fingerprints hard-block
DQG-234|S31|Distractor outside technical answer universe hard-blocks
DQG-235|S31|Distractor lacking one identifiable fatal flaw hard-blocks
DQG-236|S31|Distractor containing several unrelated defects hard-blocks
DQG-237|S31|Weak or absurd distractor hard-blocks
DQG-238|S31|Missing scenario evidence hard-blocks
DQG-239|S31|Missing temptation rationale hard-blocks
DQG-240|S31|Missing counterfactual hard-blocks
DQG-241|S31|Missing source support hard-blocks
DQG-242|S31|Unsupported assumption in KEY hard-blocks
DQG-243|S31|KEY identifiable by wording or formatting hard-blocks
DQG-244|S31|KEY uniquely detailed hard-blocks
DQG-245|S31|KEY uniquely long or short in a cueing manner hard-blocks
DQG-246|S31|Numerical distractor without reasoning provenance hard-blocks
DQG-247|S31|Calculation inconsistency hard-blocks
DQG-248|S31|Incorrect answer key hard-blocks
DQG-249|S31|Question relying on trivia rather than intended competency hard-blocks
DQG-250|S31|Question requiring information absent from stem hard-blocks
DQG-251|S31|Unresolved ambiguity hard-blocks
DQG-252|S31|Distractor and KEY equivalence under stated scenario hard-blocks
DQG-253|S32|Publication eligibility status vocabulary is restricted to PASS or BLOCK
DQG-254|S32|Warnings may exist during authoring only
DQG-255|S32|Unresolved warnings prevent published status
DQG-256|S32|Final BLOCK_COUNT equals zero
DQG-257|S32|Final FAIL_COUNT equals zero
DQG-258|S32|Final WARNING_COUNT equals zero
DQG-259|S32|Final status also requires DQS=100 and DQ_LEVEL=DQ6
DQG-260|S33|Machine rule requires optionCount==4
DQG-261|S33|Machine rule requires keyCount==1
DQG-262|S33|Machine rule requires distractorCount==3
DQG-263|S33|Machine rule requires difficultyLevel==DQ6
DQG-264|S33|Machine rule requires every distractor plausibilityScore==5
DQG-265|S33|Machine rule requires every distractor truthComponentScore==4
DQG-266|S33|Machine rule requires every distractor confusabilityScore==4
DQG-267|S33|Machine rule requires every distractor singleFatalFlaw==true
DQG-268|S33|Machine rule requires all distractor misconceptions distinct
DQG-269|S33|Machine rule requires all scenario anchors valid
DQG-270|S33|Machine rule requires all counterfactuals valid
DQG-271|S33|Machine rule requires key uniquely superior
DQG-272|S33|Machine rule requires ambiguityDetected==false
DQG-273|S33|Machine rule requires eliminationShortcutDetected==false
DQG-274|S33|Machine rule requires sourceSupportComplete==true
DQG-275|S33|Machine rule requires dqs==100
DQG-276|S33|Machine rule requires blockCount==0, failCount==0, and warningCount==0
DQG-277|S33|Anything not satisfying the complete conjunction is NOT PUBLISHABLE
DQG-278|S34|Every CSP11 question contains one uniquely defensible BEST answer
DQG-279|S34|Every CSP11 question contains exactly three DQ6 expert near-miss distractors
DQG-280|S34|Every distractor is substantially technically correct
DQG-281|S34|Every distractor has plausibility 5/5 and Truth Component 4/4
DQG-282|S34|Every distractor remains closely confusable with the BEST answer and has one precise fatal flaw
DQG-283|S34|Every distractor targets a unique sophisticated misconception and requires subject knowledge to eliminate
DQG-284|S34|Every question achieves DQS 100/100 and passes quality, ambiguity, source, scenario, calculation, linguistic, and superiority gates
DQG-285|S34|No reduced-quality question is publishable
DQG-286|S35|Freeze candidate remains not-yet-frozen until explicit freeze approval
DQG-287|S35|No implementation may weaken or reinterpret thresholds without explicit specification change and review
DQG-288|S35|No production merge is implied by the freeze candidate
DQG-289|S35|No existing frozen question-bank architecture is changed by the candidate
DQG-290|S35|Implementation must map deterministic DQG rule IDs to the specification
DQG-291|S35|Final freeze preserves DQ6-only
DQG-292|S35|Final freeze preserves all three plausibility 5/5 requirements
DQG-293|S35|Final freeze preserves all three Truth Component 4/4 requirements
DQG-294|S35|Final freeze preserves DQS 100/100
DQG-295|S35|Final freeze preserves zero unresolved warnings
DQG-296|S35|Final freeze preserves exactly one defensible BEST answer
DQG-297|S35|Step 2 may not change Step 1 contract to fit implementation
DQG-298|S35|Missing structured evidence fails closed rather than being guessed
DQG-299|S35|No manual override or reduced-quality route may exist
DQG-300|S35|Final publication aggregate passes only when every DQG-001 through DQG-299 passes and DQG-300 is derived PASS

## Non-negotiable semantics

- All 300 DQGs are required. There is no optional DQG.
- Every failed DQG is publication-blocking.
- DQG-300 is derived. It cannot be manually set or bypassed.
- Step 2 must implement the contract. Step 2 may not rewrite the contract to fit implementation.
- Missing structured evidence fails closed rather than being guessed.
- No manual override, tolerance, rounding escape, warning escape, or reduced-quality publication route is permitted.
