# Set up, check or repair my Claude Code setup on Windows from this repo.
# It uses only what ships with Windows (Windows PowerShell) plus Claude Code
# itself: no Git, Git Bash or jq. Plugins are the one exception: Claude Code
# installs them with git clone, so without Git it sets up everything else and
# reports the plugins as one problem. macOS and Linux use setup.sh. Both read
# their lists from setup.json.
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1          check and fix
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -Check   report only
# Piped into iex without a checkout, it downloads the repo as a zip (see README).
# Files it replaces are backed up beside the original as <name>.bak.<timestamp>.
param([switch]$Check)

# A hashtable, so the functions below can count problems into it.
$AiTooling = @{ Problems = 0; Here = $PSScriptRoot }   # Here is empty under iex

function Invoke-AiToolingSetup {
  $ErrorActionPreference = 'Continue'
  $ProgressPreference = 'SilentlyContinue'   # the progress bar slows downloads to a crawl
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  $Repo = 'successful-accident/ai-tooling'
  $Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $Claude = Join-Path $HOME '.claude'

  function Ok($msg)    { Write-Host "  ok       $msg" }
  function Fixed($msg) { Write-Host "  fixed    $msg" }
  function Bad($msg)   { Write-Host "  PROBLEM  $msg"; $AiTooling.Problems++ }
  # Fix <description> <claude arguments>: run claude unless -Check, and report.
  function Fix($what, [string[]]$cmd) {
    if ($Check) { Bad $what; return }
    $out = & claude @cmd 2>&1
    if ($LASTEXITCODE -eq 0) { Fixed $what; return }
    Bad "$what (repair failed: claude $cmd)"
    $out | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | ForEach-Object { Write-Host "           $_" }
  }
  # Sync <repo file> <live file>: make the live file match the repo copy.
  function Sync($from, $to) {
    if ((Test-Path $to) -and (Get-FileHash $from).Hash -eq (Get-FileHash $to).Hash) { Ok $to; return }
    if ($Check) { Bad "$to differs from the repo"; return }
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    if (Test-Path $to) { Copy-Item $to "$to.bak.$Stamp" -Force }
    Copy-Item $from $to -Force
    Fixed $to
  }
  # Set an existing property in place, so a re-run leaves the JSON unchanged.
  function Set-Prop($obj, $name, $value) {
    if ($obj.PSObject.Properties[$name]) { $obj.$name = $value }
    else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
  }
  function ClaudeJson([string[]]$cmd) {
    try { (& claude @cmd 2>$null) -join "`n" | ConvertFrom-Json } catch { }
  }

  Write-Host 'Prerequisites'
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    $native = Join-Path $HOME '.local\bin\claude.exe'   # where the native installer puts it
    if (Test-Path $native) { Bad "claude is installed at $native, but that folder isn't on your PATH. Add it to your user PATH, open a new terminal, then run this again." }
    else { Bad 'claude is not installed. Install it with: irm https://claude.ai/install.ps1 | iex' }
    return
  }
  Ok 'claude'

  # Find the repo. Piped into iex there is no checkout, so download it as a zip.
  $Dir = $AiTooling.Here; $Tmp = $null
  if (-not $Dir -or -not (Test-Path (Join-Path $Dir 'setup.json'))) {
    $ref = if ($env:AI_TOOLING_REF) { $env:AI_TOOLING_REF } else { 'main' }   # CI sets a commit
    $Tmp = Join-Path $env:TEMP "ai-tooling-$Stamp"
    try {
      Invoke-WebRequest -UseBasicParsing "https://github.com/$Repo/archive/$ref.zip" -OutFile "$Tmp.zip" -ErrorAction Stop
      Expand-Archive "$Tmp.zip" $Tmp -ErrorAction Stop
    } catch { Bad "could not download $Repo ($($_.Exception.Message))"; return }
    $Dir = (Get-ChildItem $Tmp -Directory | Select-Object -First 1).FullName
  }
  try {
    Write-Host "Using $Dir"
    $Manifest = [IO.File]::ReadAllText((Join-Path $Dir 'setup.json')) | ConvertFrom-Json

    Write-Host 'Files'
    Sync (Join-Path $Dir 'Claude\code\CLAUDE.md') (Join-Path $Claude 'CLAUDE.md')
    foreach ($f in Get-ChildItem (Join-Path $Dir 'Claude\code\hooks') -Filter *.ps1) {
      Sync $f.FullName (Join-Path $Claude "hooks\$($f.Name)")
    }
    $skills = (Get-Item (Join-Path $Dir 'Claude\skills')).FullName
    foreach ($f in Get-ChildItem $skills -Recurse -File | Where-Object Name -ne '.DS_Store') {
      Sync $f.FullName (Join-Path $Claude ('skills' + $f.FullName.Substring($skills.Length)))
    }

    Write-Host 'Settings'
    $path = Join-Path $Claude 'settings.json'
    $raw = if (Test-Path $path) { [IO.File]::ReadAllText($path) } else { '' }
    if (-not $raw.Trim()) { $raw = '{}' }
    $before = $raw | ConvertFrom-Json | ConvertTo-Json -Depth 32
    $s = $raw | ConvertFrom-Json
    $hook = Join-Path $Claude 'hooks\block_onedrive.ps1'
    $mine = [pscustomobject][ordered]@{ matcher = $Manifest.hookMatcher; hooks = @([pscustomobject][ordered]@{
        type = 'command'; command = 'powershell.exe'
        args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $hook) }) }
    $stop = [pscustomobject][ordered]@{ hooks = @([pscustomobject][ordered]@{
        type = 'prompt'; prompt = $Manifest.stopPrompt; model = 'sonnet' }) }
    if (-not $s.PSObject.Properties['hooks']) { Set-Prop $s 'hooks' ([pscustomobject]@{}) }
    Set-Prop $s 'skillListingBudgetFraction' $Manifest.skillListingBudgetFraction
    $rest = @($s.hooks.PreToolUse | Where-Object { $_ -and -not ($_.hooks | Where-Object { $_.args -contains $hook }) })
    Set-Prop $s.hooks 'PreToolUse' (@($mine) + $rest)
    $rest = @($s.hooks.Stop | Where-Object { $_ -and -not ($_.hooks | Where-Object { "$($_.prompt)".StartsWith('Console-time check.') }) })
    Set-Prop $s.hooks 'Stop' ($rest + @($stop))
    $after = $s | ConvertTo-Json -Depth 32
    if ($after -eq $before) { Ok 'listing budget, OneDrive hook and console-time hook' }
    elseif ($Check) { Bad 'settings.json lacks the listing budget, the OneDrive hook or the console-time hook' }
    else {
      New-Item -ItemType Directory -Force $Claude | Out-Null
      if (Test-Path $path) { Copy-Item $path "$path.bak.$Stamp" -Force }
      [IO.File]::WriteAllText($path, $after, (New-Object Text.UTF8Encoding $false))
      Fixed 'settings.json'
    }

    Write-Host 'Plugins'
    $markets = ClaudeJson @('plugin', 'marketplace', 'list', '--json')
    $plugins = ClaudeJson @('plugin', 'list', '--json')
    # Claude Code installs plugins with git clone, so without Git they can't be added.
    $noGit = -not (Get-Command git -ErrorAction SilentlyContinue)
    $needGit = @()
    foreach ($mk in $Manifest.marketplaces) {
      if ($markets.repo -contains $mk) { Ok "marketplace $mk" }
      elseif ($noGit) { $needGit += "marketplace $mk" }
      else { Fix "marketplace $mk" @('plugin', 'marketplace', 'add', $mk) }
    }
    foreach ($p in $Manifest.plugins) {
      if ($plugins.id -contains $p) { Ok $p }
      elseif ($noGit) { $needGit += $p }
      else { Fix $p @('plugin', 'install', $p) }
    }
    if ($needGit) {
      Bad "not installed: $($needGit -join ', '). Claude Code installs plugins with git clone, so install Git for Windows (git-scm.com/downloads/win), then run this again."
    }

    Write-Host 'MCP servers'
    foreach ($srv in $Manifest.mcpServers.PSObject.Properties) {
      & claude mcp get $srv.Name *> $null
      if ($LASTEXITCODE -eq 0) { Ok $srv.Name }
      else { Fix $srv.Name @('mcp', 'add', '--transport', 'http', '-s', 'user', $srv.Name, $srv.Value) }
    }

    $prompt = if ($Tmp) { "https://github.com/$Repo/blob/main/Claude/system-prompt/system-prompt.md" }
              else { Join-Path $Dir 'Claude\system-prompt\system-prompt.md' }
    Write-Host @"

Do these by hand in the Claude desktop app (the script can't):
  1. Paste $prompt into
     Settings > Your Claude > Instructions for Claude.
  2. Install these plugins on your claude.ai account:
       $($Manifest.claudeAiPlugins -join ', ')
  3. Do NOT install megapowers or mattpocock-skills there. A claude.ai copy
     replaces the local one, even when it is older.
  4. Start a new Claude Code session so the changes load.
"@
  } finally {
    if ($Tmp) { Remove-Item -Recurse -Force $Tmp, "$Tmp.zip" -ErrorAction SilentlyContinue }
  }
}

Invoke-AiToolingSetup
if ($AiTooling.Problems -gt 0) { Write-Host "`n$($AiTooling.Problems) problem(s) found." }
# Exit only when run as a file: under iex, exit would close the user's window.
if ($PSCommandPath) { exit ([int]($AiTooling.Problems -gt 0)) }
