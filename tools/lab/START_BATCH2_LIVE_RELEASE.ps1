param(
  [string]$ProjectId = "csp11-exam-platform",
  [int]$WebPort = 8080
)

$ErrorActionPreference = "Stop"

$ExpectedBranch = "release-batch2-labs-only"
$ExpectedClosureSha = "fc015ae2626cce59c57362a38b49da70881dbfb0"

Write-Host ""
Write-Host "CSP11 Batch 2 LAB Live Release"
Write-Host "================================"

$inside = git rev-parse --is-inside-work-tree 2>$null
if ($inside -ne "true") {
  throw "Run this script from the CSP11 exam_platform Git repository."
}

$branch = (git branch --show-current).Trim()
if ($branch -ne $ExpectedBranch) {
  throw "Wrong branch. Expected '$ExpectedBranch' but found '$branch'."
}

$dirty = git status --porcelain
if ($dirty) {
  throw "Working tree is not clean. Commit or stash local changes before release."
}

git merge-base --is-ancestor $ExpectedClosureSha HEAD
if ($LASTEXITCODE -ne 0) {
  throw "Release branch does not contain the frozen Batch 2 closure SHA $ExpectedClosureSha."
}

Write-Host "[1/5] Verifying Firebase CLI..."
firebase --version | Out-Host

Write-Host "[2/5] Verifying Flutter..."
flutter --version | Select-Object -First 1 | Out-Host

Write-Host "[3/5] Resolving Flutter packages..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
  throw "flutter pub get failed."
}

Write-Host "[4/5] Deploying validated Firestore rules only..."
firebase deploy --only firestore:rules --project $ProjectId
if ($LASTEXITCODE -ne 0) {
  throw "Firestore rules deployment failed. Batch 2 release must not continue."
}

Write-Host ""
Write-Host "Firestore rules deployed successfully."
Write-Host "The original first 10 LABs are now blocked from learner reads by the validated rules."
Write-Host "Batch 2 is still NOT learner-visible until Q17 acceptance."
Write-Host ""
Write-Host "Admin Q16 phrase: RELEASE BATCH 2 LABS"
Write-Host "Admin Q17 phrase: ACCEPT BATCH 2 LIVE RELEASE"
Write-Host ""

Write-Host "[5/5] Starting the validated app on Chrome..."
Write-Host "After admin login, open: Admin > Batch 2 Release"
Write-Host "Run Q16 first. Verify CLOSED with Published 10/10 and Staged catalogue 10/10."
Write-Host "Then run Q17. Verify ACCEPTED with Activated learner catalogue 10/10."
Write-Host ""
Write-Host "Do not use the legacy Publishing or Release Acceptance screens for this Batch 2 release."
Write-Host ""

flutter run -d chrome --web-port $WebPort
