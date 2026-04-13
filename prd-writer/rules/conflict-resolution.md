# Conflict Resolution Rules

## Purpose
Detect and resolve conflicts between persona feedback on a PRD. This ensures the final document addresses stakeholder concerns without endless iteration.

---

## Conflict Types

### Type 1: Direct Contradiction
Two or more personas give opposing recommendations on the same aspect.

**Detection**:
- Compare `suggestions` and `concerns` across personas
- Look for opposing verbs (add vs remove, increase vs decrease)
- Look for mutually exclusive approaches

**Example**:
- Engineer: "We should use polling for simplicity"
- Designer: "We need websockets for real-time feel"

**Resolution Strategy**:
1. Identify the core tension (simplicity vs experience)
2. Refer to success metrics (what matters more for this feature?)
3. Consider user impact (favour the user if tied)
4. Make a decision and document rationale
5. Note the trade-off in the PRD

---

### Type 2: Scope Creep
One persona suggests additions that expand scope beyond the original brief.

**Detection**:
- `suggestions` that add new features not in original request
- Phrases like "it would be great if", "we could also", "while we're at it"

**Example**:
- Customer: "It would be great if this also showed related products"
- (Original brief was just about improving filter UX)

**Resolution Strategy**:
1. Acknowledge the suggestion is valuable
2. Do NOT add to current PRD scope
3. Document in the "Future Enhancements" appendix section
4. Keep the PRD focused on original goals

---

### Type 3: Missing Information
A persona raises a question that cannot be answered with current context.

**Detection**:
- Non-empty `questions` arrays from personas
- `missing_information` flags from engineer
- Confidence ratings of "low"

**Example**:
- Engineer: "What's the expected traffic volume?"
- Stakeholder: "What's the timeline for this?"

**Resolution Strategy**:
1. Flag as "Requires Input" in the Open Questions table
2. Prompt the user to provide the information
3. Do NOT proceed to final output until critical questions are answered
4. Non-critical questions can be noted for follow-up

---

### Type 4: Priority Conflict
Personas agree on what to do but disagree on priority or sequencing.

**Detection**:
- Different `scope_recommendation` values
- Conflicting `effort_estimate` vs timeline expectations
- Device/platform prioritisation disagreements

**Example**:
- Stakeholder: "Mobile must launch first"
- Designer: "Desktop has more users, should be first"

**Resolution Strategy**:
1. Refer to business metrics (where are most users?)
2. Refer to original brief (did requester specify?)
3. Consider technical dependencies (does one block the other?)
4. If still unclear, flag for human decision

---

### Type 5: Verdict Conflict
Personas return different verdicts (approve vs block).

**Detection**:
- Any persona returns `"verdict": "block"`
- Mix of "approve" and "concerns" across personas

**Example**:
- Engineer: `"verdict": "block"` (not feasible)
- Designer: `"verdict": "approve"`
- Product Lead: `"verdict": "concerns"`

**Resolution Strategy**:
1. **Any "block" verdict is critical** -- must be addressed before proceeding
2. Review the `concerns` from the blocking persona
3. Determine if the block can be resolved by:
   - Reducing scope
   - Changing approach
   - Getting more information
4. If block cannot be resolved, escalate to human decision

---

## Conflict Detection Process

1. Parse all persona responses (expect JSON format)
2. Extract from each:
   - `verdict`
   - `concerns`
   - `suggestions`
   - `questions`
   - `confidence`
3. Run comparisons:

```
FOR each pair of personas:
    IF opposing concerns exist → Flag Type 1
    IF scope-expanding suggestions exist → Flag Type 2

FOR all personas:
    IF questions array not empty → Flag Type 3
    IF verdict = "block" → Flag Type 5 (critical)

IF device/priority conflicts exist → Flag Type 4
```

4. Return structured conflict report

---

## Output Format

```json
{
  "has_conflicts": true | false,
  "critical_conflicts": true | false,
  "conflicts": [
    {
      "type": "direct_contradiction" | "scope_creep" | "missing_information" | "priority_conflict" | "verdict_conflict",
      "severity": "low" | "medium" | "high" | "critical",
      "personas_involved": ["list of personas"],
      "description": "what the conflict is",
      "recommendation": "how to resolve",
      "requires_human_decision": true | false
    }
  ],
  "unresolved_questions": [
    {
      "question": "the question",
      "asked_by": "persona name",
      "critical": true | false
    }
  ],
  "scope_creep_suggestions": [
    {
      "suggestion": "the suggestion",
      "from": "persona name",
      "add_to_future_enhancements": true
    }
  ],
  "resolution_actions": [
    "action to take to resolve conflicts"
  ]
}
```

---

## Loop Control

- **If critical conflicts exist**: MUST attempt resolution
- **If only non-critical conflicts**: Can proceed after documenting them
- **Maximum 3 loops**: After 3 iterations, output with remaining conflicts flagged for human review
- **No conflicts**: Proceed directly to finalisation
