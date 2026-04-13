# Complexity Check Rules

## Purpose
Determine whether a product request is **SMALL SCOPE** or **LARGE SCOPE**.

This decision affects:
- Which template is used (quick brief vs full PRD)
- Which persona agents are spawned
- How detailed the final output needs to be

---

## Evaluation Criteria

Assess the input against each criterion. Count how many apply:

| # | Criterion | How to Identify |
|---|-----------|-----------------|
| 1 | **Multiple engineering teams** | Requires both frontend AND backend work, or involves multiple squads |
| 2 | **Long user journey** | Multiple screens, touchpoints, or steps in the user flow |
| 3 | **Legal/compliance risk** | UK or EU implications (GDPR, consumer law, accessibility law, etc.) |
| 4 | **High customer impact** | Affects a large % of users OR touches core flows (checkout, search, account) |
| 5 | **Obvious large scope** | Requester has indicated this is substantial, or it's clearly a major initiative |

---

## Decision Logic

```
count = number of criteria that apply

IF count >= 2:
    scope = "LARGE"
ELSE:
    scope = "SMALL"
```

---

## Examples

### Small Scope (0-1 criteria met)

| Request | Criteria Met | Decision |
|---------|--------------|----------|
| "Add a tooltip to the filter button" | 0 | SMALL |
| "Change the colour of the 'Add to basket' button" | 0 | SMALL |
| "Add loading spinner to search results" | 1 (customer impact, minor) | SMALL |
| "Fix alignment issue on product cards" | 0 | SMALL |
| "Update copy on the returns policy page" | 0 | SMALL |

### Large Scope (2+ criteria met)

| Request | Criteria Met | Decision |
|---------|--------------|----------|
| "Redesign the checkout flow" | 4 (multiple teams, long journey, legal, high impact) | LARGE |
| "Add BNPL payment option" | 3 (multiple teams, legal, high impact) | LARGE |
| "Build product recommendations carousel" | 2 (multiple teams, customer impact) | LARGE |
| "Implement GDPR cookie consent" | 3 (legal, multiple teams, high impact) | LARGE |
| "New user onboarding flow" | 3 (long journey, multiple teams, high impact) | LARGE |

---

## Edge Cases

### When uncertain, lean LARGE
If you're unsure whether something meets a criterion, it's safer to classify as LARGE. This ensures proper review.

### CEO requests default to LARGE
Any request from Jack should be treated as LARGE scope regardless of apparent complexity -- it likely has visibility requirements.

### Legal/compliance always counts
If there's ANY legal or compliance implication (GDPR, consumer rights, accessibility), that criterion is met.

---

## Output

After assessment, return:

```json
{
  "scope": "small" | "large",
  "criteria_met": [
    "list of criteria that were met"
  ],
  "criteria_count": 0-5,
  "confidence": "high" | "medium" | "low",
  "notes": "any relevant context for the decision"
}
```
