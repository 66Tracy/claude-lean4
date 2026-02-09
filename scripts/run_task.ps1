param(
  [Parameter(Mandatory = $true)]
  [string]$Id,
  [string]$Image = "leanprovercommunity/lean4:claude",
  [string]$Jsonl = "miniF2F-benchmark\test-example.jsonl",
  [string]$Template = "miniF2F-benchmark\task-template.md",
  [bool]$RequireSubmit = $true,
  [int]$MinSubmitBytes = 1,
  [int]$TimeoutSec = 600
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$ElanCache = Join-Path $Root ".elan-cache"

if (-not (Test-Path $ElanCache)) {
  New-Item -ItemType Directory -Force -Path $ElanCache | Out-Null
}

# Prepare task workspace
& (Join-Path $ScriptDir 'prepare_task.ps1') -Id $Id -Jsonl $Jsonl -Template $Template | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$TaskRoot = Join-Path $Root (".scratch\tasks\{0}" -f $Id)

# Bootstrap elan cache if missing
$elanBin = Join-Path $ElanCache "bin\elan"
if (-not (Test-Path $elanBin)) {
  $bootstrapArgs = @(
    "run", "--rm", "--pull=never",
    "-v", "${ElanCache}:/elan-cache",
    $Image,
    "-lc", "cp -a /home/lean/.elan/. /elan-cache/"
  )
  & docker @bootstrapArgs
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

# Run claude with the task file as prompt, write stdout to /task/claude.out
$cmd = "set -a; source /workspace/.env; set +a; python3 /workspace/scripts/run_claude_from_task.py /task/task-$Id.md /task/claude.out"

$containerName = "task_{0}_{1}" -f $Id, ([guid]::NewGuid().ToString("N"))
$dockerArgs = @(
  "run", "-d", "--pull=never", "--name", $containerName,
  "-v", "${Root}:/workspace:ro",
  "-v", "${ElanCache}:/home/lean/.elan",
  "-v", "${TaskRoot}:/task",
  "-e", "LAKE_DIR=/task/.lake",
  "-w", "/workspace",
  $Image,
  "-lc", $cmd
)

$containerId = & docker @dockerArgs
if ($LASTEXITCODE -ne 0 -or -not $containerId) {
  Write-Error "Failed to start container"
  exit 1
}

$elapsed = 0
$running = $true
while ($elapsed -lt $TimeoutSec) {
  $running = (& docker inspect -f "{{.State.Running}}" $containerName).Trim()
  if ($running -eq "false") { break }
  Start-Sleep -Seconds 2
  $elapsed += 2
}

$timedOut = ($running -ne "false")
if ($timedOut) {
  & docker stop $containerName | Out-Null
}

$exitCodeStr = (& docker inspect -f "{{.State.ExitCode}}" $containerName).Trim()
if (-not $exitCodeStr) { $exitCodeStr = "unknown" }
& docker rm $containerName | Out-Null

$submitLean = Join-Path $TaskRoot "submit.lean"
$submitMd = Join-Path $TaskRoot "submit.md"
$claudeOut = Join-Path $TaskRoot "claude.out"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# If submit files are empty, try to extract from claude.out
function Write-IfEmpty($path, $content) {
  if (-not (Test-Path $path) -or (Get-Item $path).Length -lt $MinSubmitBytes) {
    if ($content -and $content.Trim().Length -gt 0) {
      [System.IO.File]::WriteAllText($path, $content.Trim() + "`n", $utf8NoBom)
    }
  }
}

if (Test-Path $claudeOut) {
  $raw = Get-Content -Raw $claudeOut
  $leanOut = ""
  $mdOut = ""
  if ($raw -match "(?s)===SUBMIT_LEAN===\\s*(.*?)\\s*===SUBMIT_MD===\\s*(.*)$") {
    $leanOut = $Matches[1]
    $mdOut = $Matches[2]
  }

  Write-IfEmpty $submitLean $leanOut
  Write-IfEmpty $submitMd $mdOut
}

$issues = @()
if (-not (Test-Path $claudeOut) -or (Get-Item $claudeOut).Length -lt 1) {
  $issues += "claude.out is missing or empty"
}
if ($RequireSubmit) {
  if (-not (Test-Path $submitLean) -or (Get-Item $submitLean).Length -lt $MinSubmitBytes) {
    $issues += "submit.lean is missing or empty"
  }
  if (-not (Test-Path $submitMd) -or (Get-Item $submitMd).Length -lt $MinSubmitBytes) {
    $issues += "submit.md is missing or empty"
  }
}

$status = [pscustomobject]@{
  id = $Id
  timed_out = $timedOut
  exit_code = $exitCodeStr
  ok = ($issues.Count -eq 0)
  issues = $issues
  claude_out = $claudeOut
  submit_lean = $submitLean
  submit_md = $submitMd
  timestamp = (Get-Date).ToString("s")
}

$statusPath = Join-Path $TaskRoot "status.json"
[System.IO.File]::WriteAllText($statusPath, ($status | ConvertTo-Json -Depth 3), $utf8NoBom)

if ($timedOut) {
  Write-Error ("Task timed out after {0}s" -f $TimeoutSec)
  exit 3
}

if ($issues.Count -gt 0) {
  Write-Error ("Task completed with issues: " + ($issues -join "; "))
  exit 2
}

Write-Host "Task run complete. Outputs in: $TaskRoot"
