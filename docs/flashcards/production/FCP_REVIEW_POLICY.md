# FCP Human Review Policy

Status: FROZEN

Automated validation does not constitute human technical approval.

Every final production card must receive:

```text
ACCEPT
REJECT
HOLD
```

Recommended reason codes:

```text
ACCEPT
REJECT_DUPLICATE
REJECT_INACCURATE
REJECT_TOO_TRIVIAL
REJECT_WRONG_PLACEMENT
REJECT_POOR_SOURCE
REJECT_NOT_FLASHCARD_CONCEPT
REJECT_OVERLY_BROAD
REJECT_OVERLY_NARROW
HOLD_SOURCE
HOLD_TECHNICAL_REVIEW
HOLD_CONCEPT_BOUNDARY
HOLD_WORDING
HOLD_REGULATORY_CONTEXT
```

Final FCP-10 closure requires:

```text
HOLD = 0
BLANK = 0
UNREVIEWED = 0
```

An automated authoring process must never mark its own output as human-reviewed.
