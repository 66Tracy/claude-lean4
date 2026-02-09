param(
  [string]$Cmd = "lake env lean examples/test.lean",
  [string]$Image = "leanprovercommunity/lean4:claude"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$ElanCache = Join-Path $Root ".elan-cache"

if (-not (Test-Path $ElanCache)) {
  New-Item -ItemType Directory -Force -Path $ElanCache | Out-Null
}

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

$dockerArgs = @(
  "run", "--rm", "--pull=never",
  "-v", "${Root}:/workspace:ro",
  "-v", "${ElanCache}:/home/lean/.elan",
  "-e", "LAKE_DIR=/scratch/.lake",
  "--tmpfs", "/scratch:exec,mode=1777",
  "-w", "/workspace",
  $Image,
  "-lc", $Cmd
)

& docker @dockerArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
