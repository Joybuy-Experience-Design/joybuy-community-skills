---
name: translate-meeting
description: Extract, translate, and summarize a JoyMinutes meeting. Reads the transcript and metadata directly from the rendered DOM — works on both /minutes/<id> and /video/<id> URL formats. Produces a translated transcript file and a cultural-context summary file in British English.
argument-hint: <joyminutes-url>
allowed-tools: Read, Write, AskUserQuestion, mcp__Claude_in_Chrome__tabs_context_mcp, mcp__Claude_in_Chrome__tabs_create_mcp, mcp__Claude_in_Chrome__navigate, mcp__Claude_in_Chrome__javascript_tool, mcp__Claude_in_Chrome__computer
---

# JoyMinutes Meeting Translator

Extracts a JoyMinutes meeting transcript directly from the rendered DOM, then translates it to British English with cultural-context notes.

**Supported URL formats:** both `https://joyminutes.jd.com/minutes/<id>` and `https://joyminutes.jd.com/video/<id>` — identical extraction logic.

**Prerequisites:**
- Logged into joyminutes.jd.com in Chrome
- Claude in Chrome extension active and connected

**Do NOT try to intercept the `minutes.*` APIs:** `read_network_requests` only returns URL/method/status, not response bodies. Earlier versions of this skill tried that path and it doesn't work. DOM extraction is the only reliable path.

---

## Step 1: Output Directory

Read `~/.translate-meeting-config.json`.
- **If missing:** Ask the user for their preferred output directory, save as `{"outputDir": "<path>"}`, and `mkdir -p` the directory.
- **If exists:** Use stored `outputDir`. Briefly confirm: "Saving to [path]".

## Step 2: Handle Multiple URLs for the Same Meeting

If the user provides **two URLs for the same meeting** (typically one `/video/<id>` and one `/minutes/<id>`), that means JoyMinutes created two independent recordings — one per participant's account. Each recording has its own STT pass, slightly different start/end times, and very different speaker-percentage splits (the account holder's voice dominates their own mic).

Rule: pick the URL where the **dominant speaker's percentage is highest**. That's the cleanest mic capture. You can see the percentages on the meeting header (`.joynote-speakers-list-item`) after the page loads. If the user only gives one URL, just use it.

## Step 3: Open Meeting in Chrome

1. `tabs_context_mcp` with `createIfEmpty: true`
2. `tabs_create_mcp` — new tab
3. `navigate` to `$ARGUMENTS`
4. Wait ~6 seconds for the page to load.
5. If you detect a login page instead of a meeting, tell the user: "Please log into joyminutes.jd.com in Chrome first, then try again." and stop.

## Step 4: Activate the Text Record Tab (JS click, not `find`)

The transcript (`.joynote-slate-editor-container`) only mounts once the "文字记录" (Text Record) tab is active. `/video/<id>` usually opens already on this tab; `/minutes/<id>` opens on 智能纪要 (AI Summary) by default. A JS click is idempotent and handles both cases — **don't use `find` + `computer.left_click`**, it silently fails on `/minutes/`.

Run via `javascript_tool`:

```js
(function() {
  const tabs = Array.from(document.querySelectorAll('[role="tab"]'));
  const target = tabs.find(t => t.innerText.trim() === '文字记录');
  if (!target) return 'tab not found';
  target.click();
  return 'clicked';
})()
```

Then wait 4–5 seconds for the slate editor to mount.

## Step 5: Extract Transcript and Metadata from the DOM

Run one `javascript_tool` call that parses the transcript, merges consecutive same-speaker turns (STT often splits one utterance), stores the compact raw form on `window.__raw`, and returns metadata:

```js
(function() {
  const slate = document.querySelector('.joynote-slate-editor-container');
  if (!slate || !slate.children[0]) return JSON.stringify({ error: 'slate editor not mounted' });
  const full = slate.children[0].innerText;

  // Parse: every pair of lines = "{speaker}{HH:MM:SS}" then "{text}"
  const lines = full.split('\n');
  const turns = [];
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^(.+?)(\d\d:\d\d:\d\d)$/);
    if (m) { turns.push({ s: m[1], t: m[2], text: lines[i + 1] || '' }); i++; }
  }

  const merged = [];
  for (const tn of turns) {
    if (merged.length && merged[merged.length - 1].s === tn.s) merged[merged.length - 1].text += tn.text;
    else merged.push({ ...tn });
  }
  window.__raw = merged.map(m => m.s + '|' + m.t + '|' + m.text).join('\n');

  const titleEl = document.querySelector('.joynote-video-header-left-title-text-plain');
  const detailEl = document.querySelector('.joynote-video-header-left-title-detail');
  const speakers = Array.from(document.querySelectorAll('.joynote-speakers-list-item')).map(el => el.innerText.trim());

  return JSON.stringify({
    title: titleEl ? titleEl.innerText.trim() : null,
    dateAndDuration: detailEl ? detailEl.innerText.trim() : null,
    speakers,
    turns: turns.length,
    merged: merged.length,
    rawLen: window.__raw.length,
    firstTime: merged[0] ? merged[0].t : null,
    lastTime: merged[merged.length - 1] ? merged[merged.length - 1].t : null
  });
})()
```

Selectors used:
- **Title:** `.joynote-video-header-left-title-text-plain`
- **Date + duration** (e.g. `2026年4月14日 10:10\n40分45秒`): `.joynote-video-header-left-title-detail`
- **Speakers + percentages** (e.g. `林苗苗（Melody）27%`, `Olivia Forster8%`): `.joynote-speakers-list-item`
- **Transcript container:** `.joynote-slate-editor-container > :first-child`, as `innerText`

## Step 6: Retrieve the Full Transcript in Chunks

`javascript_tool` truncates output around ~1500 visible characters per call. Pull `window.__raw` out in 800-char slices via `window.__raw.substring(offset, offset + 800)` until you've covered `rawLen`. Avoid base64 — the output filter blocks it. Plain Chinese + pipe-separated lines pass through fine.

## Step 7: Validate

Count merged turns. Report: **"Extracted [N] turns from '[title]' ([date], [duration]). Translating now..."**

If 0 turns: tell the user the transcript appears empty — either the meeting has no recording, the Text Record tab didn't activate, or the user isn't authenticated. Ask them to verify in Chrome.

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
