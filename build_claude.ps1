param(
  [string]$Tag = "leanprovercommunity/lean4:claude",
  [string]$Dockerfile = "Dockerfile.claude.latest"
)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
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