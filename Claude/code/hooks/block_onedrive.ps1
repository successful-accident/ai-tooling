# PreToolUse hook for Windows: deny any tool call that names a OneDrive folder.
# Same rule as block_onedrive.sh: a path component that starts with "onedrive",
# ignoring case, so OneDrive, OneDrive-<tenant> and "OneDrive - Name" all match.
# It needs only Windows PowerShell, so it works without Git Bash or jq.
# Limit: it can't see a recursive search started from a parent folder.

$t = ([Console]::In.ReadToEnd() | ConvertFrom-Json).tool_input
$targets = @($t.file_path, $t.notebook_path, $t.path, $t.pattern, $t.command) -join "`n"

if ($targets -match '(^|[^a-z0-9_])onedrive') {
  [Console]::Error.WriteLine('Access blocked: OneDrive is off-limits.')
  exit 2
}
exit 0
