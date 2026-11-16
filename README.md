# AI-Tooling

This repo holds my prompts, instructions and skills for AI tools. The files here
are copies. The live versions are in each app, so after you change one there,
copy it back here and commit.

## Claude

| Path | What it is | Where the live copy is |
|---|---|---|
| `Claude/system-prompt/system-prompt.md` | Desktop and claude.ai system prompt (also covers Cowork) | Settings > Your Claude > Instructions for Claude (pasted in) |
| `Claude/cowork/` | Notes on Cowork, plus any folder or project instructions worth keeping | Cowork Customize panel, project settings |
| `Claude/code/CLAUDE.md` | Global Claude Code instructions | `~/.claude/CLAUDE.md` |
| `Claude/code/commands/` | Claude Code slash commands | `~/.claude/commands/` |
| `Claude/skills/<name>/` | Unpacked skill source (`SKILL.md`, scripts, references) | `~/.claude/skills/<name>/` for Claude Code; uploaded as a `.skill` zip for the desktop app |

Add subagent definitions under `Claude/code/agents/` (live copies go in
`~/.claude/agents/`).

## Refreshing copies

```zsh
cp ~/.claude/CLAUDE.md Claude/code/CLAUDE.md
cp ~/.claude/commands/*.md Claude/code/commands/
```

To build a skill for upload to the desktop app (`.skill` files are gitignored):

```zsh
cd Claude/skills && zip -r ../../my-skill.skill my-skill -x '*/__pycache__/*'
```

Never commit API keys or tokens. Skills read them from environment variables.
