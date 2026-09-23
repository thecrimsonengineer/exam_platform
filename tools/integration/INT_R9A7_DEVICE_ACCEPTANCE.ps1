[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,

    [string]$PackageId = "com.example.exam_platform",

    [string]$ExpectedCertSha256 = "97C014CA29254343FE825B8CDB9BFBE1830E8D619FEDAC0F263C4164AA5206BD",

    [switch]$SkipInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Stage {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Normalize-Sha256 {
    param([string]$Value)
    return ($Value -replace "[:\s]", "").ToUpperInvariant()
}

function Invoke-Adb {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [switch]$AllowFailure
    )

    $output = & $script:AdbPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "adb $($Arguments -join ' ') failed with exit code $exitCode. Output: $($output -join [Environment]::NewLine)"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = @($output)
    }
}

function Add-Evidence {
    param(
        [string]$Key,
        [string]$Value
    )

    $script:Evidence[$Key] = $Value
    Write-Host ("{0}={1}" -f $Key, $Value)
}

function Read-Acceptance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    if ($SkipInteractive) {
        Add-Evidence -Key $Key -Value "NOT_RUN"
        return
    }

    while ($true) {
        $answer = (Read-Host "$Prompt [PASS/FAIL/NA]").Trim().ToUpperInvariant()
        if ($answer -in @("PASS", "FAIL", "NA")) {
            Add-Evidence -Key $Key -Value $answer
            return
        }
        Write-Host "Enter PASS, FAIL, or NA." -ForegroundColor Yellow
    }
}

$resolvedApk = (Resolve-Path -LiteralPath $ApkPath).Path
if (-not (Test-Path -LiteralPath $resolvedApk -PathType Leaf)) {
    throw "APK not found: $ApkPath"
}

$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
if ($null -eq $adbCommand) {
    throw "adb was not found in PATH. Install Android platform-tools or add adb to PATH."
}
$script:AdbPath = $adbCommand.Source

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputRoot = Join-Path (Get-Location) "INT-R9A7-device-acceptance-$timestamp"
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

$script:Evidence = [ordered]@{}
Add-Evidence -Key "INT_R9A7_DEVICE_ACCEPTANCE" -Value "STARTED"
Add-Evidence -Key "APK_PATH" -Value $resolvedApk
Add-Evidence -Key "PACKAGE_ID" -Value $PackageId
Add-Evidence -Key "STARTED_AT" -Value (Get-Date).ToString("o")

Write-Stage "ADB device preflight"
& $script:AdbPath start-server | Out-Null
$deviceRows = @(& $script:AdbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" })
if ($deviceRows.Count -ne 1) {
    throw "Exactly one authorized Android device is required. Found $($deviceRows.Count). Run 'adb devices' and resolve authorization/offline devices."
}

$serial = (($deviceRows[0] -split "\t")[0]).Trim()
Add-Evidence -Key "DEVICE_SERIAL" -Value $serial
Add-Evidence -Key "DEVICE_MANUFACTURER" -Value ((Invoke-Adb -Arguments @("shell", "getprop", "ro.product.manufacturer")).Output -join "").Trim()
Add-Evidence -Key "DEVICE_MODEL" -Value ((Invoke-Adb -Arguments @("shell", "getprop", "ro.product.model")).Output -join "").Trim()
Add-Evidence -Key "ANDROID_VERSION" -Value ((Invoke-Adb -Arguments @("shell", "getprop", "ro.build.version.release")).Output -join "").Trim()
Add-Evidence -Key "ANDROID_SDK" -Value ((Invoke-Adb -Arguments @("shell", "getprop", "ro.build.version.sdk")).Output -join "").Trim()
Add-Evidence -Key "DEVICE_BUILD_FINGERPRINT" -Value ((Invoke-Adb -Arguments @("shell", "getprop", "ro.build.fingerprint")).Output -join "").Trim()

Write-Stage "APK integrity and optional signer verification"
$apkHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedApk).Hash.ToUpperInvariant()
Add-Evidence -Key "APK_SHA256" -Value $apkHash
Add-Evidence -Key "APK_SIZE_BYTES" -Value ((Get-Item -LiteralPath $resolvedApk).Length.ToString())

$apksignerCandidates = @()
foreach ($sdkRoot in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
    if (-not [string]::IsNullOrWhiteSpace($sdkRoot)) {
        $buildTools = Join-Path $sdkRoot "build-tools"
        if (Test-Path $buildTools) {
            $apksignerCandidates += Get-ChildItem -Path $buildTools -Filter "apksigner*" -File -Recurse -ErrorAction SilentlyContinue
        }
    }
}

if ($apksignerCandidates.Count -gt 0) {
    $apksigner = ($apksignerCandidates | Sort-Object FullName -Descending | Select-Object -First 1).FullName
    $verifyOutput = & $apksigner verify --verbose --print-certs $resolvedApk 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "apksigner verification failed: $($verifyOutput -join [Environment]::NewLine)"
    }

    $verifyOutput | Set-Content -LiteralPath (Join-Path $outputRoot "apksigner.txt") -Encoding UTF8
    $certLine = $verifyOutput | Where-Object { $_ -match "certificate SHA-256 digest:" } | Select-Object -First 1
    if ($null -eq $certLine) {
        throw "Could not read APK signer SHA-256 from apksigner output."
    }

    $actualCert = Normalize-Sha256 (($certLine -split ":\s*", 2)[1])
    $expectedCert = Normalize-Sha256 $ExpectedCertSha256
    Add-Evidence -Key "APK_SIGNER_SHA256" -Value $actualCert
    Add-Evidence -Key "EXPECTED_SIGNER_SHA256" -Value $expectedCert

    if ($actualCert -ne $expectedCert) {
        throw "APK signer mismatch. Expected $expectedCert but found $actualCert."
    }

    Add-Evidence -Key "APK_SIGNER_MATCH" -Value "PASS"
}
else {
    Add-Evidence -Key "APK_SIGNER_MATCH" -Value "NOT_CHECKED_APKSIGNER_UNAVAILABLE"
}

Write-Stage "Existing installation state"
$beforePath = Invoke-Adb -Arguments @("shell", "pm", "path", $PackageId) -AllowFailure
$wasInstalled = $beforePath.ExitCode -eq 0 -and (($beforePath.Output -join "") -match "package:")
Add-Evidence -Key "APP_INSTALLED_BEFORE" -Value ($(if ($wasInstalled) { "true" } else { "false" }))

$beforeDump = ""
if ($wasInstalled) {
    $beforeDump = ((Invoke-Adb -Arguments @("shell", "dumpsys", "package", $PackageId)).Output -join [Environment]::NewLine)
    $beforeDump | Set-Content -LiteralPath (Join-Path $outputRoot "package-before.txt") -Encoding UTF8

    $beforeVersionName = [regex]::Match($beforeDump, "versionName=([^\s]+)").Groups[1].Value
    $beforeVersionCode = [regex]::Match($beforeDump, "versionCode=(\d+)").Groups[1].Value
    Add-Evidence -Key "VERSION_NAME_BEFORE" -Value $beforeVersionName
    Add-Evidence -Key "VERSION_CODE_BEFORE" -Value $beforeVersionCode
}

Write-Stage "Install or update APK"
$installArgs = @("install")
if ($wasInstalled) {
    $installArgs += "-r"
}
$installArgs += $resolvedApk

$installResult = Invoke-Adb -Arguments $installArgs
$installText = ($installResult.Output -join [Environment]::NewLine)
$installText | Set-Content -LiteralPath (Join-Path $outputRoot "adb-install.txt") -Encoding UTF8

if ($installText -notmatch "Success") {
    throw "ADB install did not report Success. Output: $installText"
}
Add-Evidence -Key "ADB_INSTALL_OR_UPDATE" -Value "PASS"

$afterDump = ((Invoke-Adb -Arguments @("shell", "dumpsys", "package", $PackageId)).Output -join [Environment]::NewLine)
$afterDump | Set-Content -LiteralPath (Join-Path $outputRoot "package-after.txt") -Encoding UTF8

$afterVersionName = [regex]::Match($afterDump, "versionName=([^\s]+)").Groups[1].Value
$afterVersionCode = [regex]::Match($afterDump, "versionCode=(\d+)").Groups[1].Value
Add-Evidence -Key "VERSION_NAME_AFTER" -Value $afterVersionName
Add-Evidence -Key "VERSION_CODE_AFTER" -Value $afterVersionCode

Write-Stage "Cold launch and process health"
Invoke-Adb -Arguments @("shell", "am", "force-stop", $PackageId) | Out-Null
Invoke-Adb -Arguments @("logcat", "-c") | Out-Null
$launch = Invoke-Adb -Arguments @("shell", "monkey", "-p", $PackageId, "-c", "android.intent.category.LAUNCHER", "1")
($launch.Output -join [Environment]::NewLine) | Set-Content -LiteralPath (Join-Path $outputRoot "launch.txt") -Encoding UTF8
Start-Sleep -Seconds 8

$pidResult = Invoke-Adb -Arguments @("shell", "pidof", $PackageId) -AllowFailure
$pid = (($pidResult.Output -join "").Trim())
if ([string]::IsNullOrWhiteSpace($pid)) {
    throw "App process is not running after cold launch."
}
Add-Evidence -Key "COLD_LAUNCH_PROCESS_RUNNING" -Value "PASS"
Add-Evidence -Key "APP_PID" -Value $pid

$activityDump = ((Invoke-Adb -Arguments @("shell", "dumpsys", "activity", "activities")).Output -join [Environment]::NewLine)
$activityDump | Set-Content -LiteralPath (Join-Path $outputRoot "activity.txt") -Encoding UTF8
if ($activityDump -match [regex]::Escape($PackageId)) {
    Add-Evidence -Key "PACKAGE_VISIBLE_IN_ACTIVITY_STATE" -Value "PASS"
}
else {
    Add-Evidence -Key "PACKAGE_VISIBLE_IN_ACTIVITY_STATE" -Value "WARN"
}

$logResult = Invoke-Adb -Arguments @("logcat", "--pid=$pid", "-d", "-v", "threadtime") -AllowFailure
if ($logResult.ExitCode -ne 0) {
    $logResult = Invoke-Adb -Arguments @("logcat", "-d", "-v", "threadtime")
}
$appLog = ($logResult.Output -join [Environment]::NewLine)
$appLogPath = Join-Path $outputRoot "app-logcat.txt"
$appLog | Set-Content -LiteralPath $appLogPath -Encoding UTF8

if ($appLog -match "(?im)FATAL EXCEPTION|AndroidRuntime.*FATAL|Process:\s*$([regex]::Escape($PackageId)).*has died") {
    Add-Evidence -Key "COLD_LAUNCH_FATAL_CRASH_SCAN" -Value "FAIL"
}
else {
    Add-Evidence -Key "COLD_LAUNCH_FATAL_CRASH_SCAN" -Value "PASS"
}

Write-Stage "Physical handset acceptance"
Read-Acceptance -Key "STARTUP_ANIMATION_VISUAL" -Prompt "Does the CSP11 startup animation render smoothly, without blank frames, clipping, or repeated screens?"
Read-Acceptance -Key "UPDATE_DATA_CONTINUITY" -Prompt "If this was an update, did the app update without uninstalling and retain the expected learner/app state?"
Read-Acceptance -Key "FIREBASE_LOGIN" -Prompt "Can a real learner sign in successfully with Firebase authentication?"
Read-Acceptance -Key "SUPABASE_AUTHORIZATION" -Prompt "After sign-in, does authorization complete and allow the learner into the authorized app shell/Home?"
Read-Acceptance -Key "HOME_RENDERING" -Prompt "Does Home render correctly, including Search CSP Content and Continue CSP?"
Read-Acceptance -Key "FR9_PROTECTED_QUESTION_DELIVERY" -Prompt "Can the learner open protected practice/question content successfully?"
Read-Acceptance -Key "FR10_PROTECTED_STUDY_CONTENT" -Prompt "Can the learner open protected StudyContent successfully?"
Read-Acceptance -Key "CONNECTIVITY_LOSS_FAIL_CLOSED" -Prompt "With connectivity removed, does protected online access fail closed without exposing an insecure bypass?"
Read-Acceptance -Key "CONNECTIVITY_RECOVERY" -Prompt "After connectivity is restored, does the learner recover without reinstalling or clearing app data?"
Read-Acceptance -Key "LOGOUT_RELOGIN" -Prompt "Does logout followed by real learner re-login complete correctly?"
Read-Acceptance -Key "SCREEN_CAPTURE_BLOCKED" -Prompt "Does Android block screenshots/screen recording for the app as intended?"
Read-Acceptance -Key "NO_VISIBLE_RELEASE_REGRESSION" -Prompt "Is the release free from obvious layout, navigation, startup, authentication, or content regressions?"

$interactiveKeys = @(
    "STARTUP_ANIMATION_VISUAL",
    "UPDATE_DATA_CONTINUITY",
    "FIREBASE_LOGIN",
    "SUPABASE_AUTHORIZATION",
    "HOME_RENDERING",
    "FR9_PROTECTED_QUESTION_DELIVERY",
    "FR10_PROTECTED_STUDY_CONTENT",
    "CONNECTIVITY_LOSS_FAIL_CLOSED",
    "CONNECTIVITY_RECOVERY",
    "LOGOUT_RELOGIN",
    "SCREEN_CAPTURE_BLOCKED",
    "NO_VISIBLE_RELEASE_REGRESSION"
)

$automatedPass =
    $script:Evidence["ADB_INSTALL_OR_UPDATE"] -eq "PASS" -and
    $script:Evidence["COLD_LAUNCH_PROCESS_RUNNING"] -eq "PASS" -and
    $script:Evidence["COLD_LAUNCH_FATAL_CRASH_SCAN"] -eq "PASS" -and
    $script:Evidence["APK_SIGNER_MATCH"] -notlike "FAIL*"

$manualFailures = @()
foreach ($key in $interactiveKeys) {
    if ($script:Evidence[$key] -eq "FAIL") {
        $manualFailures += $key
    }
}

if ($SkipInteractive) {
    $finalStatus = $(if ($automatedPass) { "AUTOMATED_PASS_MANUAL_PENDING" } else { "FAIL" })
}
elseif (-not $automatedPass -or $manualFailures.Count -gt 0) {
    $finalStatus = "FAIL"
}
else {
    $finalStatus = "PASS"
}

Add-Evidence -Key "FINAL_STATUS" -Value $finalStatus
Add-Evidence -Key "COMPLETED_AT" -Value (Get-Date).ToString("o")

$txtPath = Join-Path $outputRoot "INT-R9A7-device-acceptance.txt"
$jsonPath = Join-Path $outputRoot "INT-R9A7-device-acceptance.json"

$script:Evidence.GetEnumerator() |
    ForEach-Object { "{0}={1}" -f $_.Key, $_.Value } |
    Set-Content -LiteralPath $txtPath -Encoding UTF8

$script:Evidence |
    ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath $jsonPath -Encoding UTF8

Write-Host ""
Write-Host "INT-R9A7 evidence written to:" -ForegroundColor Green
Write-Host "  $txtPath"
Write-Host "  $jsonPath"
Write-Host "  $appLogPath"
Write-Host ""
Write-Host "FINAL_STATUS=$finalStatus" -ForegroundColor $(if ($finalStatus -eq "PASS") { "Green" } elseif ($finalStatus -like "AUTOMATED_PASS*") { "Yellow" } else { "Red" })

if ($finalStatus -eq "FAIL") {
    exit 2
}
