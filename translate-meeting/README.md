# JoyMinutes Meeting Translator — Setup Guide

A Claude Code skill that extracts meeting transcripts from JoyMinutes, translates Chinese to English, and produces a translated transcript + summary with cultural context notes.

## What It Does

1. Opens a JoyMinutes meeting URL in Chrome
2. Switches to the "Text Record" tab and ensures original language is shown
3. Extracts the full transcript
4. Translates Chinese portions to English with:
   - Speaker name transliterations
   - Speech-to-text error corrections
   - Translator's notes for idioms and cultural context
   - Flags for potential miscommunication
5. Creates two files:
   - `*_transcript.md` — full word-for-word translated transcript
   - `*_summary.md` — key points, decisions, action items, and cultural notes

## Prerequisites

1. **Claude Code** — installed via CLI (`npm install -g @anthropic-ai/claude-code`) or using the Claude Desktop app (Code tab)
2. **Claude in Chrome extension** — install from Chrome Web Store, connect to your Claude account
3. **JoyMinutes login** — be logged into joyminutes.jd.com in Chrome before running

## Installation

Copy the `translate-meeting` folder to your personal Claude skills directory:

```bash
mkdir -p ~/.claude/skills
cp -r translate-meeting ~/.claude/skills/
```

Verify it's installed:
```bash
ls ~/.claude/skills/translate-meeting/SKILL.md
```

## Usage

In Claude Code (CLI or Desktop Code tab):

```
/translate-meeting https://joyminutes.jd.com/minutes/YOUR_MEETING_ID?lang=en_US
```

On first run, it will ask where to save output files. Your choice is remembered for future runs (stored in `~/.translate-meeting-config.json`).

## Output

Files are saved to your configured output directory:

```
~/Documents/Meeting-Transcripts/
  2026-02-05_Meeting-Title_transcript.md
  2026-02-05_Meeting-Title_summary.md
```

## Changing Output Directory

Delete or edit `~/.translate-meeting-config.json`:

```bash
rm ~/.translate-meeting-config.json
```

Next run will ask for a new directory.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Please log in" message | Log into joyminutes.jd.com in Chrome, then retry |
| Skill not found when typing `/translate-meeting` | Verify file exists at `~/.claude/skills/translate-meeting/SKILL.md` and restart Claude Code |
| Transcript is empty | Check the meeting has a transcript (some meetings don't record) |
| Translation shows JoyAI output instead of original | The skill should auto-select "Original text" — if not, manually click Translate > Original text in Chrome |
| Very long meetings cut off | The skill handles long meetings by chunking, but ensure Chrome has fully loaded the page |
