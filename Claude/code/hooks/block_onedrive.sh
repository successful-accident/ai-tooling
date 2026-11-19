#!/usr/bin/env bash
# PreToolUse hook: deny any tool call that names a OneDrive folder.
# It matches a path component that starts with "onedrive", ignoring case
# (APFS does), so OneDrive, OneDrive-<tenant> and "OneDrive - Name" all match
# under any home folder. Its own filename does not match.
# Limit: it can't see a recursive search started from a parent folder.

deny() { echo "$1" >&2; exit 2; }

command -v jq >/dev/null || deny "block_onedrive: jq is missing, so nothing can be checked. Install it: brew install jq"

targets=$(jq -r '.tool_input | [.file_path, .notebook_path, .path, .pattern, .command]
  | map(select(. != null)) | join("\n")' | tr '[:upper:]' '[:lower:]')

[[ "$targets" =~ (^|[^a-z0-9_])onedrive ]] && deny "Access blocked: OneDrive is off-limits."
exit 0
