---
name: translate-meeting
description: Extract, translate, and summarize a JoyMinutes meeting. Intercepts three known JoyMinutes API responses (transcript, speaker timelines, meeting detail) in one shot — no scrolling, no get_page_text. Produces a translated transcript file and a cultural-context summary file in British English.
argument-hint: <joyminutes-url>
allowed-tools: Read, Write, AskUserQuestion, mcp__Claude_in_Chrome__tabs_context_mcp, mcp__Claude_in_Chrome__tabs_create_mcp, mcp__Claude_in_Chrome__navigate, mcp__Claude_in_Chrome__find, mcp__Claude_in_Chrome__read_network_requests
---

# JoyMinutes Meeting Translator

Extracts a JoyMinutes meeting transcript via direct API interception, then translates it to British English with cultural-context notes.

**Prerequisites:**
- Logged into joyminutes.jd.com in Chrome
- Claude in Chrome extension active and connected

---

## Step 1: Output Directory

Read `~/.translate-meeting-config.json`.
- **If missing:** Ask the user for their preferred output directory, save as `{"outputDir": "<path>"}`, and `mkdir -p` the directory.
- **If exists:** Use stored `outputDir`. Briefly confirm: "Saving to [path]".

## Step 2: Open Meeting in Chrome

1. `tabs_context_mcp` with `createIfEmpty: true`
2. `tabs_create_mcp` — new tab
3. `navigate` to `$ARGUMENTS`
4. Wait ~5 seconds for the page to load.
5. If you detect a login page instead of a meeting, tell the user: "Please log into joyminutes.jd.com in Chrome first, then try again." and stop.

## Step 3: Ensure "Original text" and Open Text Record Tab

Switching to the Text Record tab is what triggers the API calls we want to intercept — it must happen.

1. Open the "Translate" dropdown (top-right). Options: Original text, 简体中文, English, ... If "Original text" isn't ticked, click it.
2. Click elsewhere to close the dropdown.
3. Click the **"Text Record"** tab in the right panel (use `find` if needed).
4. Wait 3–5 seconds for the network requests to complete.

**Why "Original text":** we want the raw speech-to-text output, not JoyAI's machine translation. Claude will do the translation properly.

## Step 4: Intercept the Three JoyMinutes API Responses

JoyMinutes' SPA fires three known API calls when the Text Record tab opens. All three go through `api.m.jd.com/api?functionId=<id>`. Grab their responses with three targeted `read_network_requests` calls using the `urlPattern` filter so you only get the one matching request each time — not the whole ~100-request list.

| Call | `urlPattern` | What's in the response |
|---|---|---|
| **Transcript** | `minutes.meetingrecord.query` | Every speaker turn: text, start time, speaker id |
| **Speaker timeline** | `minutes.speakers.timelines` | Canonical speaker-id-to-name mapping — use this for accurate speaker attribution |
| **Meeting detail** | `minutes.detail` | Title, date, duration, participants, AI summary, chapter breakdown |

**Do not call `get_page_text`. Do not scroll the transcript panel.**

Steps:

1. `read_network_requests` with `urlPattern: "minutes.meetingrecord.query"` → take the response body
2. `read_network_requests` with `urlPattern: "minutes.speakers.timelines"` → take the response body
3. `read_network_requests` with `urlPattern: "minutes.detail"` → take the response body

If any of the three returns zero results, wait 3 seconds and retry once. If still zero after retry, stop and tell the user: **"JoyMinutes function ID `<name>` returned no matches. The API may have been renamed. Please check the network tab in Chrome DevTools for the correct endpoint and update SKILL.md."** Do not fall back to scraping — that's what this rewrite was meant to eliminate.

## Step 5: Parse the Three JSON Responses

**From `minutes.meetingrecord.query`:** normalize into a flat list of `{speakerId, startTime, text}`. The response is typically wrapped as `{code, data: {records: [...]}}` or similar — recurse into fields named `data`, `records`, `sentences`, `items`, `list`, `content` to find the array of turns. Each turn has a speaker identifier (`speakerId`, `speaker`, `userId`, `userName`) and a start time (`startTime`, `beginTime`, `timestamp` — may be ms or seconds since meeting start; divide by 1000 if > 1e7, format as `HH:MM:SS`) and text (`text`, `content`, `sentence`).

**From `minutes.speakers.timelines`:** build a `speakerId → {name, chineseName, englishName, speakingPercentage}` map. Use this to look up the canonical name for each entry. This is the diarization data — always prefer it over guessing from the transcript text.

**From `minutes.detail`:** extract `title`, `startTime` / `date`, `duration`, `participants` (array of names). Keep the AI-generated summary text if present — it's useful seed material for **§ Summary file**, but you still write your own summary with the cultural-context additions.

## Step 6: Attach Speaker Names

For each entry from `minutes.meetingrecord.query`, look up its `speakerId` in the speaker map from `minutes.speakers.timelines` and attach the canonical name. If a speaker id has no entry in the map, fall back to whatever name field the transcript response carried, or `Unknown` as last resort.

## Step 7: Validate

Count speaker entries. Report: **"Extracted [N] entries from '[title]' ([date], [duration]). Translating now..."**

If 0 entries: tell the user the transcript appears empty — either the meeting has no recording, or the user isn't authenticated to view it. Ask them to verify in Chrome.

## Step 8: Translate → **§ Translation rules**

## Step 9: Write files → **§ Transcript file** and **§ Summary file**

---

## § Translation rules

The transcript is speech-to-text from meetings conducted primarily in Chinese with some English. STT quality varies — expect garbled text, mixed languages, and mistranscribed words.

1. **Faithful translation** — translate what was said, preserving conversational flow. Keep English portions as-is. Translate Chinese portions to English.
2. **Speaker names** — first occurrence: `Pinyin (Characters)` e.g. `Long Quan (龙泉)`. After that: Pinyin only. English names unchanged.
3. **Timestamps** — keep as-is.
4. **STT corrections** — fix obvious speech-to-text errors with inline notes: `[STT: "放针" → "反正" (anyway)]`
5. **Translator's notes** — add `[TN: ...]` for:
   - Chinese idioms or culturally-specific business phrases
   - Expressions where literal and intended meaning differ significantly
   - Polite hedging that masks disagreement or refusal
   - Language switches mid-sentence (note why the speaker switched)
6. **Preserve filler words** — `嗯`, `呃`, `哎` etc. show speaker confidence/hesitation.
7. **Language switches** — when someone switches languages (e.g. `不好意思，我直接用中文吧`), mark it clearly.
8. **British English only** — all English output that you generate (transcript body, translator's notes, STT corrections, summary, cultural notes, action items) uses British spelling and vocabulary throughout. Examples: `organise` not `organize`, `colour` not `color`, `behaviour` not `behavior`, `centre` not `center`, `analyse` not `analyze`, `realise` not `realize`, `recognised` not `recognized`, `prioritise` not `prioritize`, `favourite` not `favorite`, `licence` (noun) / `license` (verb), `practise` (verb) / `practice` (noun), `programme` (general) / `program` (software only), `whilst` is fine. **Exception:** preserve speakers' original English verbatim — don't rewrite American spellings they actually said. British English applies only to text that you the translator are producing.

**For long meetings (>30,000 characters of transcript text):**
- Translate in chunks of ~30 entries at a time
- Write each translated chunk to the transcript file incrementally using append
- After all chunks are translated, generate the summary from the completed transcript

---

## § Transcript file

Filename: `{outputDir}/YYYY-MM-DD_Meeting-Title_transcript.md`
(Sanitise title: hyphens for spaces, remove special chars, max 50 chars)

```
# [Full Meeting Title] — Full Transcript

**Date:** YYYY-MM-DD
**Duration:** [from minutes.detail]
**Participants:** [comma-separated, Pinyin (Characters) for Chinese names]
**Source:** [meeting URL]
**Translated from:** Chinese/English mix → British English by Claude

---

**[Speaker Name]** *(HH:MM:SS)*
[Translated text]

**[Speaker Name]** *(HH:MM:SS)*
[Translated text]
```

---

## § Summary file

Filename: `{outputDir}/YYYY-MM-DD_Meeting-Title_summary.md`

```
# [Full Meeting Title] — Meeting Summary

**Date:** YYYY-MM-DD
**Duration:** [duration]
**Participants:** [list with role/seniority if apparent]
**Source:** [meeting URL]

---

## Key Discussion Points
- [Main topics organised by theme, not chronologically]

## Decisions Made
- [Concrete decisions that were agreed upon]

## Action Items
- [ ] [Specific action] — **Owner:** [Name]

## Areas of Potential Miscommunication
[Flag moments where Chinese communication patterns might confuse non-Chinese speakers]

- **"[Original Chinese phrase]"**
  - Literal: "[word-for-word English]"
  - Intended meaning: "[what the speaker actually meant]"
  - Context: [why this matters for understanding]

[Watch especially for:]
- Indirect refusals: "我们再看看" (let's see = probably won't happen)
- Soft hedging: "可能需要..." (might need = definitely needs)
- Face-saving: criticism disguised as suggestions
- Hierarchical signals: deference patterns, who speaks when
- "不太方便" (not convenient = no), "基本上" (basically = with caveats)
- Implicit consensus without explicit verbal agreement
- Decisions framed as questions to preserve face

## Notable Context & Cultural Notes
- [Background context helpful for non-Chinese speakers]
- [Participant dynamics and power relationships]
- [Unspoken implications or implicit agreements]
```

---

## Done

Tell the user: **"Meeting translated! Files saved to [outputDir]/"** and list both full file paths.
