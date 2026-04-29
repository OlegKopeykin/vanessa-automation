<#
.SYNOPSIS
  Snapshot-сравнение двух каталогов allure-results: legacy vs stream.

.DESCRIPTION
  Используется для верификации Stage 5+ (двойная запись).
  Игнорирует поля uuid / start / stop / historyId (нестабильные).

.PARAMETER Baseline
  Каталог с allure-results, сгенерированный legacy-репортёром.

.PARAMETER Candidate
  Каталог с allure-results, сгенерированный stream-репортёром.

.EXAMPLE
  .\diff-allure.ps1 -Baseline ./allure-legacy -Candidate ./allure-stream
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$Baseline,
    [Parameter(Mandatory=$true)] [string]$Candidate
)

$ErrorActionPreference = 'Stop'

# Удаляем нестабильные поля из JSON-ов перед сравнением
$IgnoreFields = @('uuid','historyId','start','stop','testCaseId','fullUuid','attachments')

function Normalize-AllureJson($path) {
    $obj = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($f in $IgnoreFields) { if ($obj.PSObject.Properties[$f]) { $obj.PSObject.Properties.Remove($f) } }
    if ($obj.steps) {
        foreach ($s in $obj.steps) {
            foreach ($f in $IgnoreFields) { if ($s.PSObject.Properties[$f]) { $s.PSObject.Properties.Remove($f) } }
        }
    }
    return ConvertTo-Json $obj -Depth 32 -Compress
}

$baseFiles = Get-ChildItem -Path $Baseline -Filter '*-result.json' -ErrorAction SilentlyContinue
$candFiles = Get-ChildItem -Path $Candidate -Filter '*-result.json' -ErrorAction SilentlyContinue

# Сопоставление по name+fullName (UUID игнорируем)
$baseIdx = @{}
foreach ($f in $baseFiles) {
    $obj = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $key = "$($obj.name)|$($obj.fullName)"
    $baseIdx[$key] = Normalize-AllureJson $f.FullName
}
$candIdx = @{}
foreach ($f in $candFiles) {
    $obj = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $key = "$($obj.name)|$($obj.fullName)"
    $candIdx[$key] = Normalize-AllureJson $f.FullName
}

$onlyInBase = $baseIdx.Keys | Where-Object { -not $candIdx.ContainsKey($_) }
$onlyInCand = $candIdx.Keys | Where-Object { -not $baseIdx.ContainsKey($_) }
$diff       = $baseIdx.Keys | Where-Object { $candIdx.ContainsKey($_) -and $baseIdx[$_] -ne $candIdx[$_] }

Write-Host "Allure snapshot diff: $Baseline vs $Candidate"
Write-Host "  base files : $($baseFiles.Count)"
Write-Host "  cand files : $($candFiles.Count)"
Write-Host "  matched    : $(($baseIdx.Keys | Where-Object { $candIdx.ContainsKey($_) }).Count)"
Write-Host "  only base  : $($onlyInBase.Count)"
Write-Host "  only cand  : $($onlyInCand.Count)"
Write-Host "  differ     : $($diff.Count)"

if ($onlyInBase) { Write-Host "`nOnly in baseline:"; $onlyInBase | ForEach-Object { Write-Host "  - $_" } }
if ($onlyInCand) { Write-Host "`nOnly in candidate:"; $onlyInCand | ForEach-Object { Write-Host "  + $_" } }
if ($diff)       { Write-Host "`nContent differs:"; $diff | ForEach-Object { Write-Host "  ≠ $_" } }

if ($onlyInBase.Count + $onlyInCand.Count + $diff.Count -eq 0) {
    Write-Host "`nIDENTICAL ✓" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nMISMATCH ✗" -ForegroundColor Red
    exit 1
}
