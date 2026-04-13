---
name: prd-writer
description: "Create stakeholder-reviewed PRDs and quick briefs for Joybuy using an agentic multi-persona review workflow. Triggers when the user wants to write a PRD, product requirements document, product brief, feature spec, or quick brief for Joybuy. Also when they mention writing requirements for a new feature, reviewing a product idea, or creating documentation for engineering handoff. Do NOT trigger for Linear ticket specs or Figma-focused spec writing (use prd-spec-writer for those)."
argument-hint: <product brief or feature request>
allowed-tools: Agent, Read, Write, Glob, Grep, Bash, AskUserQuestion
---

# PRD Writer Skill

## Purpose
Transform product briefs into complete, stakeholder-reviewed PRDs for Joybuy. Uses an agentic workflow that spawns persona sub-agents to review from multiple perspectives, then iteratively refines through conflict-resolution loops.

## Trigger
Activate when user provides:
- A product brief or feature request
- A BRD (Business Requirements Document)
- A problem statement or metric concern
- A CEO/leadership request
- A design improvement opportunity

Input sources may include:
- **Product Lead brief**: Feature idea, A/B test idea, problem area
- **Kieran's research**: Competitor analysis, Compass analytics, past experience
- **BRD**: From business stakeholders (Category manager, marketing, legal)
- **CEO Request (Jack)**: Amazon-inspired features, broken UI/UX issues
- **Design request (TJ, Perry)**: Accessibility, UI, usability improvements

---

## Workflow

### Step 1: Complexity Assessment

Read the rules file at `rules/complexity-check.md` (relative to this skill directory).

Evaluate the user's input against the 5 complexity criteria:
1. Multiple engineering teams
2. Long user journey
3. Legal/compliance risk
4. High customer impact
5. Obvious large scope

Apply the decision logic:
- **2+ criteria met** → `scope = "large"` → Full PRD workflow
- **0-1 criteria met** → `scope = "small"` → Quick brief workflow

**Important edge cases:**
- CEO requests from Jack → always LARGE
- Any legal/compliance implication → that criterion is met
- When uncertain → lean LARGE

**Output the scope decision to the user** with reasoning before proceeding:
> "I've assessed this as **[SMALL/LARGE] scope** because [reasoning]. [X] of 5 complexity criteria are met: [list]. Proceeding with [quick brief / full PRD] workflow."

---

### Step 2: Generate Initial Document

#### If `scope = "small"`:
1. Read `templates/quick-brief-template.md`
2. Generate a quick brief covering the request
3. Keep it concise -- suitable for sending to a designer via internal chat
4. Proceed to Step 3

#### If `scope = "large"`:
1. Read `templates/prd-template.md`
2. **STOP and ask the user clarifying questions before writing:**
   - What is the core problem we're solving?
   - Who is the primary user?
   - What does success look like? (metrics)
   - Are there existing designs or references? (Figma links)
   - What is the expected timeline?
   - Who are the POC contacts? (PM, Designer, FE, BE/SA, QA)
   - Does this need design work, and is there design/engineering resource?
3. **Wait for user responses before proceeding**
4. Write the full PRD in the Joybuy template format
5. Generate appropriate **Mermaid diagrams** for Section 2.1 (see UML guidance below)
6. Proceed to Step 3

#### UML / Mermaid Diagram Generation (Large Scope)

For Section 2.1, generate **user-journey diagrams only**. The PRD describes the customer experience — engineers will design the technical flows.

| Feature Characteristic | Diagram Type | Mermaid Syntax |
|----------------------|--------------|----------------|
| User flow with decisions | Activity diagram | `flowchart TD` |
| Multiple user types or paths | Use case diagram | `flowchart LR` |

**Always include** at minimum an activity diagram showing the primary user flow for large scope PRDs.

**Do NOT include** sequence diagrams, state diagrams, or any diagram that names specific APIs, endpoints, services, or backend systems. These are implementation details that belong in the technical design phase, not the PRD.

Generate diagrams in Mermaid syntax wrapped in ` ```mermaid ` code blocks. JoySpace renders Mermaid natively.

Diagrams should use plain, user-facing language (e.g. "User sees results" not "Frontend renders SearchResultsGrid component"). Do not reference internal system names, API routes, or technical identifiers unless the user has explicitly provided them.

---

### Content Guardrails

These rules apply to ALL content you generate in the PRD. They are non-negotiable.

1. **Never fabricate data.** If the user hasn't given you a number, write "TBC". This applies to success metric targets, baselines, A/B test thresholds, and percentages. Do not invent plausible-sounding numbers.

2. **Never guess internal architecture.** Do not name APIs, services, endpoints, cache layers, databases, or infrastructure unless the user has told you about them. The PRD describes *what* the user needs, not *how* engineering builds it.

3. **Never guess team structures.** Do not assign work to teams or describe how teams are organised unless the user has told you. If you don't know, leave it out entirely.

4. **Never translate.** Joybuy has an internal localisation team. Just list the strings that need translating. Do not generate DE/FR/NL translations.

5. **Never invent timelines.** Do not add week numbers, phase durations, sprint estimates, or deadlines unless the user explicitly provides them.

6. **Competitor analysis is a placeholder** unless the user provides verified data or explicitly asks you to research competitors. Do not populate the table with information you are not certain about — it is better to leave it for the PM to fill in.

7. **Diagrams must be user-journey focused.** Activity diagrams showing the customer experience are appropriate. Sequence diagrams, state diagrams, and any diagram naming specific APIs, endpoints, or backend systems must be omitted — engineers own the technical design.

8. **Analytics is always P0.** Never deprioritise tracking or event requirements.

9. **All platforms ship together** unless the user explicitly says otherwise. Do not split features into phases by platform. Do not add a Phase column to the Platform table.

10. **Event tracking: describe in plain English.** Write what to track and why in human-readable language. Do not invent snake_case event names or technical parameter schemas. The PM will set up the actual events in Easy Analytics.

11. **Do not add escalation language or blockers** (e.g. "escalate to VP Engineering", "sprint planning cannot begin") unless the user has given you specific context about dependencies or organisational constraints.

12. **Do not add sections the template doesn't include.** Follow the template structure exactly. Do not re-add removed sections (Doc Edit History, PRD Review checklist, Data Support, Team Coordination, Rollback Criteria, View Mode, Reference, Revision History).

---

### Step 3: Persona Review Loop

Initialise loop control:
```
loop_count = 0
max_loops = 3
```

**Spawn agents based on scope:**

| Agent File | Small Scope | Large Scope |
|------------|-------------|-------------|
| `agents/product-lead.md` | Spawn | Spawn |
| `agents/engineer.md` | Spawn | Spawn |
| `agents/designer.md` | Spawn | Spawn |
| `agents/customer.md` | Skip | Spawn |
| `agents/stakeholder.md` | Skip | Spawn |

**How to spawn agents:**

For each persona agent, use the **Agent tool**. Spawn ALL applicable agents in the **SAME message** (parallel execution).

For each agent, use this prompt structure:
```
You are a reviewer agent. Follow the persona instructions below exactly.

## Persona Instructions
[Read and include the full content of the persona file from agents/<name>.md]

## Document to Review
[Include the full current PRD or quick brief text]

## Context
- Scope: [small | large]
- This is review loop [loop_count + 1] of maximum 3

## Instructions
Review the document according to your persona checklist.
Return your review ONLY as a JSON object matching the output format specified in your persona instructions.
Do not include any text outside the JSON object.
```

Set each agent's description to: `"[persona-name] PRD review"`

**On loop iterations 2 and 3:** Only re-spawn agents that returned `"verdict": "concerns"` or `"verdict": "block"` in the previous round. Agents that approved do not need to re-review.

Collect ALL agent responses before proceeding to Step 4.

---

### Step 4: Conflict Detection & Resolution

Read and apply `rules/conflict-resolution.md`.

1. Parse all persona responses (JSON format expected)
2. If a response is not valid JSON, attempt to extract JSON by finding the first `{` and last `}`. If still invalid, log the persona name as having returned malformed output and continue with valid responses.
3. Apply conflict detection rules across all responses:
   - **Type 1 - Direct Contradiction**: Opposing recommendations between personas
   - **Type 2 - Scope Creep**: Suggestions that expand beyond original brief
   - **Type 3 - Missing Information**: Unanswered questions, low confidence
   - **Type 4 - Priority Conflict**: Disagreement on sequencing/priority
   - **Type 5 - Verdict Conflict**: Mix of approve/concerns/block verdicts

4. Generate a conflict report and present to user:

**If critical conflicts exist** (any "block" verdict, or critical missing information):
- Present the conflicts to the user with recommendations
- Ask for user input on blocking items before proceeding
- Rewrite the PRD addressing each conflict
- Document decisions and rationale in Appendix B (Conflicts Resolved)
- Increment `loop_count`
- If `loop_count < max_loops`: Return to Step 3
- If `loop_count >= max_loops`: Proceed to Step 5 with remaining conflicts flagged

**If only non-critical conflicts exist:**
- Auto-resolve per the rules in `conflict-resolution.md`
- Move scope creep suggestions to Appendix C (Future Enhancements)
- Document non-critical questions in the Open Questions table
- Rewrite the PRD with resolutions
- Increment `loop_count`
- If `loop_count < max_loops`: Return to Step 3
- If `loop_count >= max_loops`: Proceed to Step 5

**If no conflicts:**
- Proceed to Step 5

---

### Step 5: Finalisation

1. Incorporate useful, non-scope-creep suggestions from persona feedback
2. Ensure all template sections are complete
3. Fill in Appendix A (Stakeholder Review Summary) with verdict and key feedback per persona
4. Format for JoySpace:
   - Clean markdown with proper headers
   - Mermaid diagrams in fenced code blocks
   - All tables properly formatted
   - No orphaned references or TODOs (except intentional Open Questions)
   - Ready for copy-paste into JoySpace

5. **Save the PRD as a markdown file** to the user's Downloads folder:
   - Filename: `[Feature-Name]-PRD.md` (kebab-case, e.g. `BNPL-Integration-PRD.md` or `Filter-Tooltip-Brief.md`)
   - Path: `~/Downloads/[filename]`
   - Use the Write tool to create the file
   - Inform the user of the saved file path

6. Output the final document in the conversation wrapped in a code block for easy copying

7. After the PRD, output a summary:
   - **Scope**: Small or Large
   - **Review loops completed**: X of 3
   - **Persona verdicts**: table of final verdicts
   - **Key decisions made**: list of conflict resolutions
   - **Unresolved items**: anything flagged for human review

---

## Output Format

The final PRD should be presented in a markdown code block:

~~~
```markdown
[Complete PRD content following template structure]
```
~~~

For small scope, use the quick brief format.
For large scope, use the full Joybuy PRD template format with all sections.

---

## Error Handling

- **Insufficient context**: Ask clarifying questions before proceeding
- **Malformed agent responses**: Extract JSON if possible, continue with valid responses
- **Max loops reached with conflicts**: Flag remaining conflicts in Open Questions table for human decision
- **Template load failure**: Inform user and provide inline fallback structure

---

## Notes

- All persona agents return JSON-structured responses for programmatic conflict detection
- The 3-loop maximum prevents infinite revision cycles
- Small scope still includes designer review to catch UX issues early
- This skill requires Claude Code for agentic execution (Agent tool for subagent spawning)
- UML diagrams use Mermaid syntax for JoySpace compatibility
