# Meeting Translator — Setup Guide

A Claude Code skill that extracts a JoyMinutes meeting transcript directly from the rendered DOM and produces a translated transcript plus a cultural-context summary in British English.

Works on both `/minutes/<id>` and `/video/<id>` URL formats — identical extraction logic. If you have two URLs for the same meeting (one per participant's account), the skill picks the recording with the cleanest mic capture.

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

Both URL formats work:
- `https://joyminutes.jd.com/minutes/<id>` (AI Summary view)
- `https://joyminutes.jd.com/video/<id>` (Video view)

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
| "Extracted 0 turns" / transcript appears empty | The Text Record tab (文字记录) probably didn't activate, or you aren't authenticated. Open the meeting in Chrome yourself, click the Text Record tab, confirm the transcript renders, then retry |
| Slate editor selectors no longer match | JoyMinutes changed their DOM. Open Chrome DevTools → Elements, find the new classes for the transcript container, title, date/duration and speakers list, and update the selectors in `SKILL.md` § Step 5 |
