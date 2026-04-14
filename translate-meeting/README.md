# Meeting Translator — Setup Guide

A Claude Code skill that pulls a JoyMinutes meeting transcript via direct API interception and produces a translated transcript plus a cultural-context summary in British English.

The skill intercepts three known JoyMinutes API responses in one shot — no scrolling, no repeated `get_page_text`. Much cheaper on tokens than scraping the DOM.

**Outputs:**
- `*_transcript.md` — full word-for-word translated transcript
- `*_summary.md` — key points, decisions, action items, and cultural notes

## Prerequisites

- **Claude Code** — CLI (`npm install -g @anthropic-ai/claude-code`) or Desktop app
- **Claude in Chrome extension** — install from the Chrome Web Store and connect it to your Claude account
- **JoyMinutes login** — logged into joyminutes.jd.com in Chrome

## Installation

```bash
mkdir -p ~/.claude/skills
cp -r translate-meeting ~/.claude/skills/
```

Restart Claude Code so it picks up the new skill.

## Usage

```
/translate-meeting https://joyminutes.jd.com/minutes/YOUR_MEETING_ID?lang=en_US
```

On first run, the skill asks where to save output files and stores the answer in `~/.translate-meeting-config.json`.

## Output

```
~/Documents/Meeting-Transcripts/
  2026-04-14_Weekly-Standup_transcript.md
  2026-04-14_Weekly-Standup_summary.md
```

## Changing Output Directory

```bash
rm ~/.translate-meeting-config.json
```

The next run will ask for a new directory.

## Troubleshooting

| Problem | Solution |
|---|---|
| "Please log in" message | Log into joyminutes.jd.com in Chrome, then retry |
| Skill not found when typing `/translate-meeting` | Verify `~/.claude/skills/translate-meeting/SKILL.md` exists and restart Claude Code |
| "JoyMinutes function ID ... returned no matches" | JoyMinutes renamed an API endpoint. Open Chrome DevTools → Network while loading a meeting, find the new `functionId`, and update the `urlPattern` values in `SKILL.md` § Step 4 |
| Translation shows JoyAI output instead of original text | The skill auto-selects "Original text" in the Translate dropdown; if it didn't, click Translate → Original text manually and retry |
