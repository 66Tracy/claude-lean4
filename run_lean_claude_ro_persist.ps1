param(
  [string]$Cmd = "lake env lean test.lean",
  [string]$Image = "leanprovercommunity/lean4:claude",
  [string]$ScratchDir = ".scratch"
)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ElanCache = Join-Path $Root ".elan-cache"
$Scratch = Join-Path $Root $ScratchDir

if (-not (Test-Path $ElanCache)) {
  New-Item -ItemType Directory -Force -Path $ElanCache | Out-Null
}

if (-not (Test-Path $Scratch)) {
  New-Item -ItemType Directory -Force -Path $Scratch | Out-Null
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

# Unique per-run Lake volume to avoid lock contention
$LakeVolume = "lake_cache_{0}" -f ([guid]::NewGuid().ToString("N"))

$dockerArgs = @(
  "run", "--rm", "--pull=never",
  "-v", "${Root}:/workspace:ro",
  "-v", "${ElanCache}:/home/lean/.elan",
  "-v", "${Scratch}:/scratch",
  "--mount", "type=volume,source=$LakeVolume,target=/workspace/.lake",
  "-w", "/workspace",
  $Image,
  "-lc", $Cmd
)

& docker @dockerArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }