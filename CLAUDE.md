# Joybuy Community Skills — Installation Instructions

This file tells Claude how to install the skills from this repository into a user's local Claude Code setup.

## When a user asks you to install these skills

Follow these steps exactly:

### Step 1: Check the current state

Check if `~/.claude/skills/` exists. If not, create it:
```bash
mkdir -p ~/.claude/skills
```

### Step 2: Copy each skill

Copy each skill directory from this repository into `~/.claude/skills/`. The skill directories are:

- `prd-writer/`
- `translate-meeting/`

Use this command pattern for each:
```bash
cp -R <repo-path>/<skill-name> ~/.claude/skills/
```

Do NOT copy the following files — they are repo-level files, not skills:
- `README.md`
- `CLAUDE.md`
- `install.sh`
- `.git/`
- `.gitignore`

### Step 3: Verify

```bash
ls ~/.claude/skills/
```

Expected output should include `prd-writer/` and `translate-meeting/`.

### Step 4: Inform the user

Tell the user:
- Both skills have been installed
- They should start a new Claude Code conversation (or restart) for the skills to be picked up
- They can use `/prd-writer` or `/translate-meeting` as slash commands
- Some skills have prerequisites (see README.md for details)

## When a user asks you to update skills

Follow the same copy steps above. The `-R` flag with `cp` will overwrite existing files. Remind the user to restart Claude Code after updating.
