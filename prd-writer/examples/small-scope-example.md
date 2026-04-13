# Quick Brief: Add Tooltip to Filter Button

**Type**: Small Scope
**Requested by**: Perry (Design)
**Date**: 2024-01-15

---

## What
Add an informational tooltip to the "Filters" button on the product listing page to explain what filters are available.

## Why
User research showed 23% of users don't realise they can filter by multiple categories. A tooltip on hover/tap will increase filter usage.

## Requirements
- Tooltip appears on hover (desktop) and tap (mobile)
- Tooltip text: "Filter by price, category, rating, and more"
- Tooltip dismisses on click elsewhere or after 3 seconds
- Follow existing tooltip component styling

## Design Notes
- Devices: Mobile & Desktop
- Accessibility: Tooltip must be keyboard accessible (focusable)
- Existing patterns: Use `<Tooltip>` component from design system

## Acceptance Criteria
- [ ] Tooltip appears on filter button hover/focus
- [ ] Tooltip contains correct copy
- [ ] Tooltip is keyboard accessible
- [ ] Tooltip auto-dismisses after 3 seconds on mobile
- [ ] Styling matches existing tooltips

## Notes from Review
- **Product Lead (Kieran)**: Approved. Good quick win for usability.
- **Engineer**: Straightforward. Existing Tooltip component handles accessibility. ~2 hour task.
- **Designer**: Approved. Recommend using existing Tooltip component with `position="bottom"`.

---

*Ready for designer handoff via internal chat*
