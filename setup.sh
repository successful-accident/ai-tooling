#!/usr/bin/env bash
# Set up, check or repair my Claude Code setup from this repo on macOS or Linux.
# Windows uses setup.ps1. Both read their lists from setup.json.
#   ./setup.sh           check everything and fix what's wrong
#   ./setup.sh --check   report only, change nothing
#   ./setup.sh --cloud   print a setup script for a Claude Code cloud environment
# Files it replaces are backed up beside the original as <name>.bak.<timestamp>.
set -u

REPO=successful-accident/ai-tooling
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*)
  echo "This is Windows. Run setup.ps1 from PowerShell instead:"
  echo "  irm https://raw.githubusercontent.com/$REPO/main/setup.ps1 | iex"
  exit 1 ;;
esac
CHECK=""; [ "${1:-}" = "--check" ] && CHECK=1
STAMP=$(date +%Y%m%d-%H%M%S)
PROBLEMS=0

ok()    { echo "  ok       $1"; }
fixed() { echo "  fixed    $1"; }
bad()   { echo "  PROBLEM  $1"; PROBLEMS=$((PROBLEMS + 1)); }
# fix <description> <command...>: run the command unless --check, and report.
fix()   { local what=$1; shift
          if [ -n "$CHECK" ]; then bad "$what"
          elif "$@" >/dev/null 2>&1; then fixed "$what"
          else bad "$what (repair failed: $*)"; fi; }

# Find the repo. Piped from curl there is no checkout, so clone or update one.
DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)
if [ ! -f "$DIR/setup.sh" ] || [ ! -d "$DIR/Claude" ]; then
  DIR="${AI_TOOLING_DIR:-$HOME/.ai-tooling}"
  if [ -d "$DIR/.git" ]; then git -C "$DIR" pull --ff-only -q
  else git clone -q "https://github.com/$REPO.git" "$DIR"; fi || { echo "Could not get $REPO"; exit 1; }
fi

# The cloud script clones the public repo with git (the raw file CDN can serve
# a stale setup.sh for a while) and runs this script from the clone.
# It must exit 0 or the session fails to start. Plugin installs work there
# (undocumented, confirmed 2026-11-19).
if [ "${1:-}" = "--cloud" ]; then
  cat <<EOF
#!/usr/bin/env bash
# Set up Claude Code from $REPO. Output goes to ~/.claude/cloud-setup.log.
mkdir -p ~/.claude
{ if [ -d ~/.ai-tooling/.git ]; then git -C ~/.ai-tooling pull -q --ff-only
  else git clone -q --depth 1 https://github.com/$REPO.git ~/.ai-tooling; fi
  ~/.ai-tooling/setup.sh; } > ~/.claude/cloud-setup.log 2>&1
exit 0
EOF
  exit 0
fi
echo "Using $DIR"

echo "Prerequisites"
for tool in claude jq git; do
  if command -v "$tool" >/dev/null; then ok "$tool"; else bad "$tool is not installed"; fi
done
[ "$PROBLEMS" -gt 0 ] && { echo "Install the missing tools, then run this again."; exit 1; }
M="$DIR/setup.json"

# sync <repo file> <live file>: make the live file match the repo copy.
sync() {
  if cmp -s "$1" "$2"; then ok "$2"; return; fi
  if [ -n "$CHECK" ]; then bad "$2 differs from the repo"; return; fi
  mkdir -p "$(dirname "$2")"
  [ -e "$2" ] && cp -f "$2" "$2.bak.$STAMP"
  cp -f "$1" "$2" && fixed "$2"
}

echo "Files"
sync "$DIR/Claude/code/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
for f in "$DIR"/Claude/code/hooks/*.sh; do
  sync "$f" "$HOME/.claude/hooks/$(basename "$f")"
  [ -n "$CHECK" ] || chmod +x "$HOME/.claude/hooks/$(basename "$f")"
done
while read -r f; do
  sync "$DIR/Claude/skills/$f" "$HOME/.claude/skills/$f"
done < <(cd "$DIR/Claude/skills" && find . -type f ! -name .DS_Store | sed 's|^\./||')

echo "Settings"
SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || { [ -n "$CHECK" ] || echo '{}' > "$SETTINGS"; }
HOOK="$HOME/.claude/hooks/block_onedrive.sh"
# A prompt hook on Stop: a small model reads each final reply and sends it back
# if it wastes the time of a user who runs the commands by hand.
STOP_PROMPT=$(jq -r .stopPrompt "$M")
WANT=$(jq --arg cmd "$HOOK" --arg m "$(jq -r .hookMatcher "$M")" --arg sp "$STOP_PROMPT" \
  --argjson b "$(jq .skillListingBudgetFraction "$M")" '
  .skillListingBudgetFraction = $b
  | .hooks.PreToolUse = [{matcher: $m, hooks: [{type: "command", command: $cmd}]}]
      + ((.hooks.PreToolUse // []) | map(select(any(.hooks[]?; .command == $cmd) | not)))
  | .hooks.Stop = ((.hooks.Stop // [])
      | map(select(any(.hooks[]?; (.prompt // "") | startswith("Console-time check.")) | not)))
      + [{hooks: [{type: "prompt", prompt: $sp, model: "sonnet"}]}]
  ' "$SETTINGS" 2>/dev/null || echo '{}')
if [ "$(echo "$WANT" | jq -S .)" = "$(jq -S . "$SETTINGS" 2>/dev/null)" ]; then ok "listing budget, OneDrive hook and console-time hook"
elif [ -n "$CHECK" ]; then bad "settings.json lacks the listing budget, the OneDrive hook or the console-time hook"
else cp -f "$SETTINGS" "$SETTINGS.bak.$STAMP"; echo "$WANT" > "$SETTINGS"; fixed "settings.json"; fi

echo "Plugins"
MARKETS=$(claude plugin marketplace list 2>/dev/null)
PLUGINS=$(claude plugin list 2>/dev/null)
for m in $(jq -r '.marketplaces[]' "$M"); do
  if echo "$MARKETS" | grep -q "($m)"; then ok "marketplace $m"
  else fix "marketplace $m" claude plugin marketplace add "$m"; fi
done
for p in $(jq -r '.plugins[]' "$M"); do
  if echo "$PLUGINS" | grep -qE "^ *(❯|>) $p\$"; then ok "$p"
  else fix "$p" claude plugin install "$p"; fi
done

echo "MCP servers"
while read -r name url; do
  if jq -e --arg n "$name" '.mcpServers[$n]' "$HOME/.claude.json" >/dev/null 2>&1; then ok "$name"
  else fix "$name" claude mcp add --transport http -s user "$name" "$url"; fi
done < <(jq -r '.mcpServers | to_entries[] | "\(.key) \(.value)"' "$M")

cat <<EOF

Do these by hand in the Claude desktop app (the script can't):
  1. Paste $DIR/Claude/system-prompt/system-prompt.md into
     Settings > Your Claude > Instructions for Claude.
  2. Install these plugins on your claude.ai account:
$(jq -r '.claudeAiPlugins | join(", ")' "$M" | fold -s -w 72 | sed 's/ *$//; s/^/       /')
  3. Do NOT install megapowers or mattpocock-skills there. A claude.ai copy
     replaces the local one, even when it is older.
  4. Start a new Claude Code session so the changes load.
EOF

if [ "$PROBLEMS" -gt 0 ]; then echo; echo "$PROBLEMS problem(s) found."; exit 1; fi
