---
name: translate-meeting
description: Extract, translate, and summarize a JoyMinutes meeting transcript from Chinese to English. Navigates to the meeting URL, switches to the Text Record tab, extracts the full transcript, translates it, and creates a translated transcript file and a summary file.
argument-hint: <joyminutes-url>
allowed-tools: Bash, Read, Write, AskUserQuestion, mcp__Claude_in_Chrome__tabs_context_mcp, mcp__Claude_in_Chrome__tabs_create_mcp, mcp__Claude_in_Chrome__navigate, mcp__Claude_in_Chrome__find, mcp__Claude_in_Chrome__computer, mcp__Claude_in_Chrome__get_page_text
---

# JoyMinutes Meeting Translator

Extract, translate, and summarize a JoyMinutes (joyminutes.jd.com) meeting transcript.

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
4. Wait ~5 seconds, then **take a screenshot** to verify the page loaded and you're not on a login screen.
   - If you see a login page, tell the user: "Please log into joyminutes.jd.com in Chrome first, then try again."

## Step 3: Ensure Original Text & Switch to Text Record

**CRITICAL — Verify "Original text" is selected:**
1. Look at the top-right area of the page for a **"Translate"** button/dropdown.
2. Click it to open the dropdown. The options are: Original text, 简体中文, English, Français, Español, 日本語, Deutsch, Nederlands, بالعربية.
3. If "Original text" does NOT have a checkmark (✓), click "Original text" to select it.
4. Click elsewhere to close the dropdown.

**Why:** We want the raw speech-to-text output, NOT JoyAI's machine translation. Claude will do the translation properly.

**Switch to Text Record tab:**
5. The page has two tabs on the right panel: "AI Summary" (default, active) and **"Text Record"**.
6. Use `find` to locate "Text Record" and click it, OR click it directly — it's in the right panel header area.
7. Wait 2-3 seconds for transcript content to load.
8. Take a screenshot to confirm the transcript is visible (you should see speaker names, timestamps, and text).

## Step 4: Scroll to Load All Content

The transcript may be lazy-loaded or virtualized. Scroll the right-side transcript panel to trigger loading:
1. Use `computer` with `scroll_down` on the right side of the page (coordinate ~[1100, 400]).
2. Repeat scrolling until no new content appears (typically 5-15 scrolls depending on meeting length).
3. The transcript is fully loaded when you reach the last speaker entry (usually a short goodbye message).

## Step 5: Extract Full Page Text

Call `get_page_text` once. This captures everything on the page in a single efficient call.

**How to parse the output — the page text contains these sections in order:**

1. **HEADER** — Title, date (YYYY/M/D HH:MM), duration, "Translate", "Share"
2. **SPEAKERS** — "Speakers(N)" followed by names and speaking percentages (e.g. "龙泉71%")
3. **AI SUMMARY** — Chinese summary text, chapter headings with timestamps, and task list ("【Meeting Todos】")
4. **>>> TRANSCRIPT <<<** — The section we need. Starts after the AI Summary/Tasks section. Entries are concatenated as:
   ```
   SpeakerNameHH:MM:SStranscript text here...SpeakerNameHH:MM:SSnext entry...
   ```
   There is NO space or newline between the speaker name and timestamp, or between entries. Use the `HH:MM:SS` timestamp pattern to identify entry boundaries.
5. **FOOTER** — Starts with "Return to current speaking position" followed by "System.import" lines and Chinese marketing text about "慧记". **Stop parsing here.**

**Entry boundary pattern:** Each new entry starts with a speaker name immediately followed by `HH:MM:SS`. Speaker names can be:
- Chinese characters: `龙泉`, `李冰(Teresa)`
- English names: `Olly Boon`
- Mixed: `ChineseName(EnglishName)`

Use regex like `(?=(?:[\u4e00-\u9fff].+?|[A-Z][a-z]+ [A-Z][a-z]+.*?)\d{2}:\d{2}:\d{2})` to split entries, or identify them by the timestamp pattern.

## Step 6: Validate

Count speaker entries. Report: **"Extracted [N] entries from '[title]' ([date], [duration]). Translating now..."**

- If 0 entries: ask user to check login, meeting has transcript, and Text Record tab is visible
- If fewer than expected for the meeting duration (~2-3 entries per minute is typical): scrolling may not have loaded everything. Go back and scroll more.

## Step 7: Translate

The transcript is speech-to-text from meetings conducted primarily in Chinese with some English. STT quality varies — expect garbled text, mixed languages, and mistranscribed words.

**Translation rules:**
1. **Faithful translation** — translate what was said, preserving conversational flow. Keep English portions as-is. Translate Chinese portions to English.
2. **Speaker names** — first occurrence: "Pinyin (Characters)" e.g. "Long Quan (龙泉)". After that: Pinyin only. English names unchanged.
3. **Timestamps** — keep as-is.
4. **STT corrections** — fix obvious speech-to-text errors with inline notes: `[STT: "放针" → "反正" (anyway)]`
5. **Translator's notes** — add `[TN: ...]` for:
   - Chinese idioms or culturally-specific business phrases
   - Expressions where literal and intended meaning differ significantly
   - Polite hedging that masks disagreement or refusal
   - Language switches mid-sentence (note why the speaker switched)
6. **Preserve filler words** — "嗯", "呃", "哎" etc. show speaker confidence/hesitation.
7. **Language switches** — when someone switches languages (e.g. "不好意思，我直接用中文吧"), mark it clearly.

**For long meetings (>30,000 characters of page text):**
- Translate in chunks of ~30 entries at a time
- Write each translated chunk to the transcript file incrementally using append
- After all chunks are translated, generate the summary from the completed transcript

## Step 8: Write Transcript File

Filename: `{outputDir}/YYYY-MM-DD_Meeting-Title_transcript.md`
(Sanitize title: hyphens for spaces, remove special chars, max 50 chars)

```
# [Full Meeting Title] — Full Transcript

**Date:** YYYY-MM-DD
**Duration:** [from page header]
**Participants:** [comma-separated, Pinyin (Characters) for Chinese names]
**Source:** [meeting URL]
**Translated from:** Chinese/English mix → English by Claude

---

**[Speaker Name]** *(HH:MM:SS)*
[Translated text]

**[Speaker Name]** *(HH:MM:SS)*
[Translated text]
```

## Step 9: Write Summary File

Filename: `{outputDir}/YYYY-MM-DD_Meeting-Title_summary.md`

```
# [Full Meeting Title] — Meeting Summary

**Date:** YYYY-MM-DD
**Duration:** [duration]
**Participants:** [list with role/seniority if apparent]
**Source:** [meeting URL]

---

## Key Discussion Points
- [Main topics organized by theme, not chronologically]

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

## Done

Tell the user: **"Meeting translated! Files saved to [outputDir]/"** and list both full file paths.
