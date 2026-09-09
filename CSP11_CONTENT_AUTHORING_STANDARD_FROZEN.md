# CSP11 CONTENT AUTHORING STANDARD
## FROZEN DECISION

**Status:** FROZEN  
**Authority:** CSP11 Exam Platform Content Authoring  
**Applies to:** All CSP11 learning-content authoring, AI-assisted content creation, manual Studio authoring, imports, and future content-population work.

This standard MUST be read together with:

- `CSP11_FINAL_TOPIC_SUBTOPIC_ARCHITECTURE_FROZEN.md`

No content-authoring task may override the frozen Topic → Subtopic → Content architecture.

---

## 1. PURPOSE

CSP11 learning content must be:

- easy to read;
- concept-first;
- concise without becoming shallow;
- technically accurate;
- learner-facing rather than textbook-like;
- traceable to accepted source evidence;
- structured for CSP application and analysis;
- compatible with learner progress, Question Bank, validation, and repository lifecycle.

The goal is not to copy books into the app.

The goal is to transform controlled source evidence into clear CSP11 learning content.

---

## 2. AUTHORITATIVE HIERARCHY

All learner content MUST use:

`StudyContent.topics → StudyTopic.subtopics → StudySubtopic.blocks`

Learner navigation is:

`Domain → Competency → Topic → Subtopic → Learning Content`

The retired `MainContentTopic` / `mainContent` architecture MUST NOT be reintroduced.

---

## 3. SOURCE EVIDENCE GATE

The frozen L23-E4 Step 7B human-review decisions govern source eligibility.

- `ACCEPT` → eligible for content development.
- `HOLD` → quarantined; MUST NOT enter learner content until explicitly resolved.
- `REJECT` → excluded from learner content.
- `BLANK` → not permitted in the frozen reviewed dataset.

Books, PDFs, chapters, or sections are evidence sources. They are NOT automatically Topics or Subtopics.

Content authors must not freely browse the source library and add material merely because it appears useful when that material conflicts with the frozen evidence gate.

---

## 4. TOPIC DESIGN

A Topic is a coherent CSP11 learning concept within one canonical Competency.

Topics must:

- align directly with the CSP11 competency statement;
- be learner-facing and plainly named;
- use stable deterministic IDs;
- avoid simply copying source-book chapter names;
- group related concepts without becoming excessively broad;
- end with learner revision/support material and references where appropriate.

Recommended deterministic ID pattern:

`d##_c##_t##`

Example:

`d07_c05_t03`

---

## 5. SUBTOPIC DESIGN

A Subtopic is the main learner study and progress unit beneath a Topic.

Subtopics must:

- teach one manageable concept or closely related concept set;
- use easy-to-read language;
- introduce simple concepts before complexity;
- avoid unnecessary academic prose;
- have stable globally unique IDs within the content package;
- retain stable IDs after publication because Subtopic IDs participate in learner-progress identity.

Recommended deterministic ID pattern:

`d##_c##_t##_s##`

Example:

`d07_c05_t03_s02`

A Subtopic must not be split merely to create more screens. Split only when doing so improves learning.

---

## 6. FLEXIBLE CONTENT-BLOCK PHILOSOPHY

There is NO rigid requirement that every Subtopic contain the same blocks.

Use only the blocks that genuinely improve understanding.

A strong Subtopic MAY include:

- Heading
- Short introduction
- What is it?
- Why is it used?
- When should it be used?
- How it works / key steps
- Main advantages
- Main limitations
- Simple safety example
- Comparison table
- Common mistake
- Warning / caution
- Remember
- Exam tip
- Key point to remember
- Mini workplace scenario
- Check Your Understanding
- Practice-question link or Question Bank entry point
- Image or diagram where genuinely useful
- Checklist
- Formula where relevant
- Case study where relevant
- Quote where relevant

The existing `ContentBlock` architecture should be used rather than inventing a parallel content format.

Not every Subtopic needs every block.

A small concept may need only a few blocks.
A major concept may need many.

The content must breathe rather than follow a mechanical template.

---

## 7. CORE EXPLANATORY SPINE

Where useful, the explanatory spine is:

1. What is it?
2. Why is it used?
3. When should it be used?
4. How does it work / what are the important features?
5. Main advantages
6. Main limitations
7. Simple safety or workplace example
8. Key point to remember

This is a guide, NOT a mandatory fixed template.

Blocks such as scenarios, tables, warnings, exam tips, and checks for understanding should be added when they improve learning.

---

## 8. CSP APPLICATION ORIENTATION

CSP11 learning must support application and analysis, not rote memorization alone.

Significant Topics should include short workplace scenarios where useful.

Scenarios should help learners decide:

- which method/control/tool is most suitable;
- why one choice is better than another;
- what limitation changes the decision;
- how a safety professional should apply the concept.

Do not turn every paragraph into an exam question.

---

## 9. EXAM TIPS

Exam Tips should:

- highlight a useful decision rule;
- explain how CSP scenarios may distinguish similar concepts;
- help the learner notice important qualifiers;
- remain technically accurate;
- avoid claiming access to actual BCSP examination questions.

Exam Tips must not become shortcuts that replace understanding.

---

## 10. REMEMBER / KEY TAKEAWAY BLOCKS

Use `Remember` or equivalent callouts for:

- high-value distinctions;
- decision rules;
- commonly confused concepts;
- safety-critical principles;
- concise revision points.

Avoid repeating the preceding paragraph word-for-word.

---

## 11. WARNINGS AND COMMON MISTAKES

Use warnings for genuine:

- safety implications;
- misuse of a method;
- important limitations;
- interpretation traps.

Use Common Mistake blocks for likely learner misconceptions.

Do not overuse warning blocks merely for visual variety.

---

## 12. TABLES AND COMPARISONS

Use tables when learners benefit from comparing:

- methods;
- strengths and weaknesses;
- suitable vs unsuitable applications;
- selection factors;
- responsibilities;
- sequence or criteria.

Tables must remain readable on mobile.

Do not place long essay paragraphs inside table cells.

---

## 13. CHECK YOUR UNDERSTANDING

A Subtopic may contain a lightweight `Check Your Understanding` prompt.

This may be:

- a short conceptual question;
- a one-step scenario;
- a reflective decision prompt;
- a revealable answer/explanation where supported by the UI.

These lightweight checks are NOT replacements for the authoritative Question Bank.

---

## 14. PRACTICE QUESTIONS

Formal CSP11 Practice Questions remain managed by the existing Question Bank architecture.

They MUST retain the normal Question Bank rules, including:

- canonical Domain / Competency / Topic / Subtopic identity;
- exactly 4 options;
- exactly 1 BEST/correct answer;
- H0.3 quality-gate validation;
- explanation;
- reference;
- required tags/metadata;
- appropriate difficulty and cognitive level;
- lifecycle controls.

Questions should be linked to the appropriate:

- `competencyId`
- `topicId`
- `subtopicId`

Do not hard-code formal practice questions as ordinary learning-content prose when they belong in the Question Bank.

---

## 15. TOPIC-END LEARNING BLOCKS

Where appropriate, each Topic may end with:

- Topic Summary
- Key Takeaways
- CSP Exam Tips
- Topic Practice Questions
- References

The exact set may vary according to the Topic.

---

## 16. REFERENCES

Visible learner references should normally appear at the END OF EACH TOPIC rather than cluttering every paragraph.

However, internal evidence traceability MUST be preserved at a finer level.

For important content, the system/content-development record should be able to trace back to:

- source ID;
- source title;
- edition/year where available;
- chapter/section;
- page or page range where available;
- relevant Step 7B mapping/review identity.

Multiple sources may support one learning explanation.

Where sources overlap, consolidate rather than duplicate.

Where sources materially disagree, flag the conflict for review rather than silently choosing one.

---

## 17. COPYRIGHT-SAFE AUTHORING

Learning content should synthesize and explain source evidence in original learner-facing wording.

Do not reproduce long passages from copyrighted source books.

Use quotations only where genuinely necessary and appropriately limited.

Source references must remain traceable even when the learner-facing text is paraphrased.

---

## 18. READABILITY STANDARD

Content should be understandable on first reading by a serious CSP learner.

Prefer:

- short paragraphs;
- clear headings;
- direct explanations;
- familiar safety examples;
- defined technical terms;
- progressive complexity;
- useful comparisons.

Avoid:

- unnecessarily academic wording;
- oversized paragraphs;
- unexplained jargon;
- content included only because it appears in a reference;
- repetitive definitions;
- decorative complexity.

Simple does not mean technically weak.

---

## 19. PROGRESS INTEGRATION RULE

Content authoring MUST preserve learner-progress identity.

The current application persists Subtopic learning progress by stable `subtopicId` and content version.

Therefore:

- published Subtopic IDs MUST remain stable;
- renaming a learner-facing title should not require changing the stable ID;
- Content Blocks do NOT receive independent learner-progress identities under this standard;
- authoring must not create hidden hierarchy levels between Topic and Subtopic;
- content population must not reset or invalidate existing learner progress unintentionally.

Topic-level progress aggregation is a separate implementation concern and MUST be audited against the final Topic → Subtopic architecture before any new Topic-progress behavior is frozen.

---

## 20. CONTENT COMPLETION AND PROGRESS

The learner currently studies and completes content at the Subtopic level.

A content author must therefore make each Subtopic a meaningful completion unit.

A Subtopic should not be marked conceptually complete merely because one block was viewed.

Completion behavior remains controlled by the student progress implementation, not by arbitrary content-block authoring.

Any future automatic completion, scroll-based completion, block-level completion, or quiz-gated completion requires a separate explicit architectural decision.

---

## 21. VALIDATION EXPECTATIONS

Before publication, populated content should be checked for:

- canonical competency ID;
- stable non-empty Topic IDs;
- stable non-empty globally unique Subtopic IDs;
- Topic → Subtopic → Blocks hierarchy;
- valid block types/data;
- no retired `MainContentTopic` / `mainContent` dependency;
- source eligibility against frozen Step 7B;
- reference/provenance completeness;
- valid Question Bank links;
- readable learner presentation;
- no accidental duplicate content;
- no unsupported claims.

---

## 22. AI / CHATGPT AUTHORING RULE

Any AI or ChatGPT session working on CSP11 content should, when repository context is available:

1. read `AGENTS.md`;
2. read `CSP11_FINAL_TOPIC_SUBTOPIC_ARCHITECTURE_FROZEN.md`;
3. read `CSP11_CONTENT_AUTHORING_STANDARD_FROZEN.md`;
4. respect frozen Step 7B decisions;
5. inspect relevant accepted source evidence before generating final learning content;
6. preserve canonical IDs and progress identity;
7. keep formal questions in the Question Bank architecture;
8. place learner-visible references at Topic end while preserving internal evidence traceability.

If a requested change conflicts with a frozen rule, stop and request explicit authorization to unfreeze or amend the rule.

---

## 23. FROZEN CONTENT PHILOSOPHY

The CSP11 learner experience is:

**CORE EXPLANATION  
+ EXAMPLES  
+ TABLES / COMPARISONS  
+ WARNINGS  
+ REMEMBER  
+ EXAM TIPS  
+ SCENARIOS  
+ CHECK YOUR UNDERSTANDING  
+ QUESTION BANK QUESTIONS  
+ TOPIC SUMMARY  
+ REFERENCES**

This is a flexible authoring palette, not a mandatory block checklist.

The final test is whether the learner can understand, apply, revise, and trace the concept effectively.

---

## 24. CHANGE CONTROL

This document is FROZEN.

Do not silently alter the standard.

Any material change requires explicit authorization from Naveed and should be committed as a deliberate revision with an updated checksum.

END OF FROZEN CSP11 CONTENT AUTHORING STANDARD
