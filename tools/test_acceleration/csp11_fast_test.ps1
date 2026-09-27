param(
  [ValidateSet("impacted", "smoke", "full")]
  [string]$Mode = "impacted",

  [string]$Base = "HEAD~1",

  [string]$Head = "HEAD",

  [string]$Shards = "auto",

  [int]$Workers = 1,

  [int]$Concurrency = 4
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $repoRoot

try {
  $pythonLauncher = Get-Command py -ErrorAction SilentlyContinue

  $argsList = @(
    "tools/test_acceleration/csp11_test_accelerator.py",
    "local",
    "--mode", $Mode,
    "--base", $Base,
    "--head", $Head,
    "--shards", $Shards,
    "--workers", $Workers,
    "--concurrency", $Concurrency
  )

  if ($pythonLauncher) {
    & py -3 @argsList
  } else {
    & python @argsList
  }

  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
