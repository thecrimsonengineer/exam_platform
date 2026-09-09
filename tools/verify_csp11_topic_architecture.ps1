# CSP11 FINAL TOPIC/SUBTOPIC ARCHITECTURE GUARD
# Frozen architectural decision effective 2026-09-07
#
# Purpose:
# Prevent accidental reintroduction of the retired MainContentTopic/mainContent
# architecture into production CSP11 code.
#
# DO NOT modify this guard to permit the retired architecture unless the frozen
# architectural decision is explicitly unfreezed by Naveed.

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$productionRoots = @(
    (Join-Path $repo "lib"),
    (Join-Path $repo "test"),
    (Join-Path $repo "content"),
    (Join-Path $repo "docs")
)

$forbiddenTerms = @(
    "MainContentTopic",
    "mainContent",
    "MainContentEditorPanel",
    "MainContentStructureCard",
    "MainContentTopicRenderer"
)

Write-Host ""
Write-Host "============================================================"
Write-Host " CSP11 FINAL TOPIC/SUBTOPIC ARCHITECTURE GUARD"
Write-Host "============================================================"
Write-Host ""

$violations = @()

foreach ($root in $productionRoots) {

    if (-not (Test-Path $root)) {
        continue
    }

    $files = Get-ChildItem `
        -Path $root `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Extension -in @(
                ".dart",
                ".json",
                ".yaml",
                ".yml",
                ".txt",
                ".md"
            )
        }

    foreach ($file in $files) {

        $relative = $file.FullName.Substring($repo.Length + 1)

        # The frozen architecture document intentionally contains the
        # historical forbidden terms, so exclude it from the production scan.
        if ($relative -eq "CSP11_FINAL_TOPIC_SUBTOPIC_ARCHITECTURE_FROZEN.md") {
            continue
        }

        $lines = Get-Content `
            -Path $file.FullName `
            -ErrorAction SilentlyContinue

        for ($i = 0; $i -lt $lines.Count; $i++) {

            foreach ($term in $forbiddenTerms) {

                if ($lines[$i] -match [regex]::Escape($term)) {

                    $violations += [PSCustomObject]@{
                        File = $relative
                        Line = $i + 1
                        Term = $term
                        Text = $lines[$i].Trim()
                    }
                }
            }
        }
    }
}

if ($violations.Count -gt 0) {

    Write-Host ""
    Write-Host "ARCHITECTURE GUARD: FAILED"
    Write-Host ""
    Write-Host "Retired CSP11 architecture detected:"
    Write-Host ""

    $violations |
        Format-Table `
            File,
            Line,
            Term,
            Text `
            -AutoSize

    Write-Host ""
    Write-Host "The following architecture is permanently retired:"
    Write-Host ""
    Write-Host "StudySubtopic -> MainContentTopic -> ContentBlock"
    Write-Host ""
    Write-Host "The approved architecture is:"
    Write-Host ""
    Write-Host "StudyContent"
    Write-Host "  -> StudyTopic"
    Write-Host "      -> StudySubtopic"
    Write-Host "          -> ContentBlocks"
    Write-Host "              -> Practice Questions"
    Write-Host ""

    exit 1
}

Write-Host "ARCHITECTURE GUARD: PASS"
Write-Host ""
Write-Host "No retired MainContentTopic/mainContent architecture was detected."
Write-Host ""
Write-Host "Approved learning-content hierarchy:"
Write-Host ""
Write-Host "Domain"
Write-Host "  -> Competency"
Write-Host "      -> Content Package"
Write-Host "          -> Content Version"
Write-Host "              -> Topic"
Write-Host "                  -> Subtopic"
Write-Host "                      -> Content Blocks"
Write-Host "                          -> Practice Questions"
Write-Host ""
Write-Host "No legacy migration."
Write-Host "No legacy compatibility layer."
Write-Host "No MainContentTopic architecture."
Write-Host ""
Write-Host "============================================================"
