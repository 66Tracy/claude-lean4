param(
  [Parameter(Mandatory = $true)]
  [string]$Id,
  [string]$Jsonl = "miniF2F-benchmark\test-example.jsonl",
  [string]$Template = "miniF2F-benchmark\task-template.md",
  [string]$OutRoot = ".scratch\tasks"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir

$jsonlPath = Join-Path $Root $Jsonl
$templatePath = Join-Path $Root $Template
$outBase = Join-Path $Root $OutRoot
$outDir = Join-Path $outBase $Id

if (-not (Test-Path $jsonlPath)) { Write-Error "JSONL not found: $jsonlPath"; exit 1 }
if (-not (Test-Path $templatePath)) { Write-Error "Template not found: $templatePath"; exit 1 }

$entry = $null
Get-Content $jsonlPath | ForEach-Object {
  if ($_ -and $_.Trim().Length -gt 0) {
    try {
      $obj = $_ | ConvertFrom-Json
      if ($obj.id -eq $Id) { $entry = $obj }
    } catch {}
  }
}

if (-not $entry) { Write-Error "Id not found in JSONL: $Id"; exit 1 }

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
if (-not (Test-Path (Join-Path $outDir 'scratch'))) { New-Item -ItemType Directory -Force -Path (Join-Path $outDir 'scratch') | Out-Null }

$templateText = Get-Content -Raw $templatePath
$taskText = $templateText.Replace('{id}', $entry.id).Replace('{question}', $entry.formal_statement)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $outDir ("task-{0}.md" -f $entry.id)), $taskText, $utf8NoBom)

# Initialize workspace files if missing
$submitLean = Join-Path $outDir 'submit.lean'
$submitMd = Join-Path $outDir 'submit.md'
$paper = Join-Path $outDir 'scratch\scratch-paper.md'
$slean = Join-Path $outDir 'scratch\scratch.lean'
$spy = Join-Path $outDir 'scratch\scratch.py'
$taskReadme = Join-Path $outDir 'README.md'

if (-not (Test-Path $submitLean)) { [System.IO.File]::WriteAllText($submitLean, "", $utf8NoBom) }
if (-not (Test-Path $submitMd)) { [System.IO.File]::WriteAllText($submitMd, "", $utf8NoBom) }
if (-not (Test-Path $paper)) { [System.IO.File]::WriteAllText($paper, "", $utf8NoBom) }
if (-not (Test-Path $slean)) { [System.IO.File]::WriteAllText($slean, "", $utf8NoBom) }
if (-not (Test-Path $spy)) { [System.IO.File]::WriteAllText($spy, "", $utf8NoBom) }
if (-not (Test-Path $taskReadme)) {
  $readmeText = @"
# Task Workspace

This directory is mounted to /task inside the container.

Do NOT run lake update or lake build (workspace is read-only).

Run Lean with Mathlib from /workspace:

  cd /workspace
  lake env lean /task/submit.lean

Or for scratch:

  cd /workspace
  lake env lean /task/scratch/scratch.lean

All writable work should go under /task.
"@
  [System.IO.File]::WriteAllText($taskReadme, $readmeText, $utf8NoBom)
}

Write-Host "Prepared task workspace: $outDir"
