param(
  [string]$Tag = "leanprovercommunity/lean4:claude",
  [string]$Dockerfile = "docker\\Dockerfile.claude.latest"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$dockerfilePath = Join-Path $Root $Dockerfile

if (-not (Test-Path $dockerfilePath)) {
  Write-Error "Dockerfile not found: $dockerfilePath"
  exit 1
}

$buildArgs = @(
  "build",
  "-f", $dockerfilePath,
  "-t", $Tag,
  $Root
)

& docker @buildArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
