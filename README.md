# Joybuy Community Skills

Claude Code skills contributed by the Joybuy product & design community. These are general-purpose workflows — PRD writing, meeting translation, and more — that anyone on the team can install into their local Claude Code setup.

For the core FigWatch Figma-audit skills (`@tone`, `@ux`), see [`joybuy-claude-skills`](https://github.com/Joybuy-Experience-Design/joybuy-claude-skills).

## Skills

| Skill | Trigger | What it does |
|-------|---------|-------------|
| **prd-writer** | `/prd-writer` or ask Claude to write a PRD | Writes stakeholder-reviewed PRDs using a multi-persona review loop (Product Lead, Engineer, Designer, Customer, Stakeholder). Outputs in Joybuy's JoySpace template format. |
| **translate-meeting** | `/translate-meeting` with a JoyMinutes URL | Extracts a Chinese meeting transcript from JoyMinutes, translates it to English, and creates a summary. Requires Chrome + Claude in Chrome extension. |

## Install

### Option 1: Run the install script

```bash
git clone https://github.com/Joybuy-Experience-Design/joybuy-community-skills.git ~/joybuy-community-skills
cd ~/joybuy-community-skills
bash install.sh
```

Restart Claude Code afterwards.

### Option 2: Ask Claude to install them

After cloning, open Claude Code and paste:

```
Install all the skills from ~/joybuy-community-skills — read the CLAUDE.md in that repo for instructions.
```

### Option 3: Manual copy

```bash
cp -R prd-writer translate-meeting ~/.claude/skills/
```

## Prerequisites

- **prd-writer** — works out of the box with just Claude Code.
- **translate-meeting** — requires Chrome with the Claude in Chrome extension, and an active session on joyminutes.jd.com.

## Updating

```bash
cd ~/joybuy-community-skills
git pull
bash install.sh
```

## Contributing

This repo is maintained by a single admin — open an issue or message the maintainer directly if you'd like to add a new skill or improve an existing one. External commits are not accepted, but suggestions are welcome.
