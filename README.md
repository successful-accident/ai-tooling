# AI-Tooling

This repo holds my prompts, instructions and skills for AI tools. The files here
are copies. The live versions are in each app, so after you change one there,
copy it back here and commit.

## Setup, check and repair

`setup.sh` sets up Claude Code on a new Mac or under a new account, and repairs
an existing setup. It is safe to run again: it skips what is already right and
backs up any file it replaces as `<name>.bak.<timestamp>`. It needs `claude`,
`jq`, `git` and a GitHub SSH key.

It copies the repo's versions over the live ones, so copy live changes back
here first (see Refreshing copies).

From a checkout:

```zsh
./setup.sh           # check everything and fix what's wrong
./setup.sh --check   # report only, change nothing
```

Without a checkout (the repo is private, so the download uses your `gh` login).
This clones the repo to `~/.ai-tooling`, or updates it, and runs from there:

```zsh
curl -fsSL -H "Authorization: Bearer $(gh auth token)" https://raw.githubusercontent.com/successful-accident/AI-Tooling/main/setup.sh | bash
```

Add `-s -- --check` after `bash` to report only.

What it covers: `CLAUDE.md`, hooks, skills, the two `settings.json` entries it
owns (the skill listing budget and the OneDrive hook), the Claude Code plugins
and the Microsoft Learn MCP server. It ends by printing what has to be done by
hand in the desktop app, including the claude.ai plugins.

### Cloud environments

Cloud sessions (claude.ai/code) can't clone this private repo, so
`./setup.sh --cloud` prints a script with `CLAUDE.md` built in. Paste it into
your own environment's Setup script field (not a shared environment). Cloud
environments cache the setup for about 7 days, so regenerate and re-paste the
script after you change `CLAUDE.md`. The script also installs the plugins and
logs that to `~/.claude/cloud-setup.log` (confirmed working 2026-11-19). Skills and the Microsoft Learn MCP reach cloud sessions
through your claude.ai account: upload the skill there and add Learn as a connector.

megapowers comes from its author's repo, which Claude Code does not update on
its own. To update it:

```zsh
claude plugin marketplace update megapowers
claude plugin update megapowers@megapowers
```

## Claude

| Path | What it is | Where the live copy is |
|---|---|---|
| `Claude/system-prompt/system-prompt.md` | Desktop and claude.ai system prompt (also covers Cowork) | Settings > Your Claude > Instructions for Claude (pasted in) |
| `Claude/cowork/` | Notes on Cowork, plus any folder or project instructions worth keeping | Cowork Customize panel, project settings |
| `Claude/code/CLAUDE.md` | Global Claude Code instructions | `~/.claude/CLAUDE.md` |
| `Claude/code/commands/` | Claude Code slash commands | `~/.claude/commands/` |
| `Claude/code/hooks/` | Claude Code hook scripts. `block_onedrive.sh` denies any tool call that names a OneDrive folder | `~/.claude/hooks/` |
| `Claude/skills/<name>/` | Unpacked skill source (`SKILL.md`, scripts, references) | `~/.claude/skills/<name>/` for Claude Code; uploaded as a `.skill` zip for the desktop app |

Add subagent definitions under `Claude/code/agents/` (live copies go in
`~/.claude/agents/`).

## Refreshing copies

```zsh
cp ~/.claude/CLAUDE.md Claude/code/CLAUDE.md
cp ~/.claude/commands/*.md Claude/code/commands/
cp ~/.claude/hooks/*.sh Claude/code/hooks/
cp -R ~/.claude/skills/<name> Claude/skills/
```

After changing `CLAUDE.md`, update `Claude/system-prompt/system-prompt.md` to
match (it is the same text without the Lessons section) and paste it into the app.

To build a skill for upload to the desktop app (`.skill` files are gitignored):

```zsh
cd Claude/skills && zip -r ../../<name>.skill <name> -x '*/__pycache__/*'
```

Never commit API keys or tokens. Skills read them from environment variables.
