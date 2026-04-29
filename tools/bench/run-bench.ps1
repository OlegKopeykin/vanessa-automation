<#
.SYNOPSIS
  Один прогон bench-замера для VA-StreamingReports.

.DESCRIPTION
  - Подставляет каталог фич и каталог Allure в шаблон VBParams.
  - Параллельно запускает семплер памяти 1C-процессов (250 ms).
  - Запускает прогон через oscript run-behavior-check-session.os.
  - По завершении считает peak RSS / WS Private / Commit и размеры выходов.
  - Дописывает строку в bench-results.csv.

.PARAMETER StageName
  Имя текущего stage'а (baseline, fix-2498, attachment-store, и т.д.).

.PARAMETER Profile
  Один из: repro2498 / heavy / selftest.

.PARAMETER N
  Размер набора: 10 / 20 / 50.

.EXAMPLE
  .\run-bench.ps1 -StageName baseline -Profile repro2498 -N 10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [string]$StageName,
    [Parameter(Mandatory=$true)]  [ValidateSet('repro2498','heavy','selftest')] [string]$Profile,
    [Parameter(Mandatory=$true)]  [ValidateSet(10,20,50)] [int]$N,
    [Parameter(Mandatory=$false)] [int]$SamplerIntervalMs = 250
)

$ErrorActionPreference = 'Stop'
$BenchRoot   = $PSScriptRoot
$RepoRoot    = Resolve-Path (Join-Path $BenchRoot '..\..')
$ToolsDir    = Join-Path $RepoRoot 'tools'
$ResultsCsv  = Join-Path $BenchRoot 'bench-results.csv'
$RunId       = "{0}_{1}_{2}_N{3}_{4}" -f $StageName, $Profile, (Get-Date -Format 'yyyyMMdd_HHmmss'), $N, [Guid]::NewGuid().ToString().Substring(0,8)

# === 1. Подготовка временного VBParams + BenchRun конфигов ===

$ProfileFeaturesDir = switch ($Profile) {
    'repro2498' { Join-Path $BenchRoot "repro2498\$N.feature" | Split-Path -Parent }
    'heavy'     { Join-Path $BenchRoot "heavy\$N.feature"     | Split-Path -Parent }
    'selftest'  { Join-Path $BenchRoot "selftest\$N.json"     | Split-Path -Parent }
}
# Для repro2498/heavy один feature-файл — кладём его в собственный изолированный подкаталог,
# чтобы run-behavior-check-session подхватил только N.feature, не все три.
if ($Profile -in 'repro2498','heavy') {
    $IsolatedFeatureDir = Join-Path $env:TEMP "va-bench-$RunId"
    New-Item -ItemType Directory -Path $IsolatedFeatureDir | Out-Null
    Copy-Item (Join-Path $ProfileFeaturesDir "$N.feature") $IsolatedFeatureDir
    $ProfileFeaturesDir = $IsolatedFeatureDir
}

$AllureDir = Join-Path $RepoRoot "tools\ServiceBases\bench-allure-$RunId"
New-Item -ItemType Directory -Force -Path $AllureDir | Out-Null

# Подстановка в шаблон VBParams. Абсолютные пути с экранированным backslash (\\),
# как в эталонных VA-конфигах — VA запускает 1С из разных cwd, относительные ломаются.
function Json-Escape-Path([string]$p) { return ([System.IO.Path]::GetFullPath($p)).Replace('\','\\') }

$VBParamsTemplate = Get-Content (Join-Path $BenchRoot 'configs\VBParams_template.json') -Raw -Encoding UTF8
$VBParamsContent  = $VBParamsTemplate.Replace('__FEATURES_DIR_REL__', (Json-Escape-Path $ProfileFeaturesDir)).Replace('__ALLURE_DIR_REL__', (Json-Escape-Path $AllureDir))
$VBParamsTmp = Join-Path $env:TEMP "VBParams-$RunId.json"
[System.IO.File]::WriteAllText($VBParamsTmp, $VBParamsContent, [System.Text.UTF8Encoding]::new($true))

# Подстановка в BenchRun
$BenchRunTemplate = Get-Content (Join-Path $BenchRoot 'configs\BenchRun.json') -Raw -Encoding UTF8
$BenchRunContent  = $BenchRunTemplate.Replace('__VBPARAMS_PATH_REL__', (Json-Escape-Path $VBParamsTmp)).Replace('__ALLURE_DIR_REL__', (Json-Escape-Path $AllureDir))
$BenchRunTmp = Join-Path $env:TEMP "BenchRun-$RunId.json"
[System.IO.File]::WriteAllText($BenchRunTmp, $BenchRunContent, [System.Text.UTF8Encoding]::new($true))

Write-Host "[bench] StageName=$StageName Profile=$Profile N=$N RunId=$RunId"
Write-Host "[bench] features: $ProfileFeaturesDir"
Write-Host "[bench] allure:   $AllureDir"

# === 2. Запуск семплера памяти в background-job ===

$SamplerCsv = Join-Path $env:TEMP "memsamples-$RunId.csv"
'timestamp,process,pid,working_set_mb,private_mb,paged_mem_mb,virtual_mb' | Set-Content $SamplerCsv -Encoding UTF8

$SamplerJob = Start-Job -ScriptBlock {
    param($csv, $intervalMs)
    while ($true) {
        $now = (Get-Date).ToString('o')
        Get-Process | Where-Object { $_.ProcessName -match '^(1cv8|1cv8c|oscript)$' } |
            ForEach-Object {
                "{0},{1},{2},{3},{4},{5},{6}" -f $now,$_.ProcessName,$_.Id,
                    [math]::Round($_.WorkingSet64/1MB,1),
                    [math]::Round($_.PrivateMemorySize64/1MB,1),
                    [math]::Round($_.PagedMemorySize64/1MB,1),
                    [math]::Round($_.VirtualMemorySize64/1MB,1) |
                    Add-Content $csv
            }
        Start-Sleep -Milliseconds $intervalMs
    }
} -ArgumentList $SamplerCsv, $SamplerIntervalMs

# === 3. Запуск прогона ===

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Push-Location $ToolsDir
try {
    $oscriptArgs = @('onescript\run-behavior-check-session.os', $BenchRunTmp)
    Write-Host "[bench] Running: oscript $($oscriptArgs -join ' ')"
    & oscript @oscriptArgs *>&1 | Tee-Object -FilePath (Join-Path $env:TEMP "run-$RunId.log")
    $exit = $LASTEXITCODE
} finally {
    Pop-Location
    $Stopwatch.Stop()
    Stop-Job -Job $SamplerJob -ErrorAction SilentlyContinue
    Remove-Job -Job $SamplerJob -Force -ErrorAction SilentlyContinue
}

# === 4. Анализ метрик ===

$samples = Import-Csv $SamplerCsv
if ($samples.Count -eq 0) {
    Write-Warning "[bench] No memory samples captured — sampler problem"
    $peakWs = $peakPriv = $peakPaged = 0
} else {
    $peakWs    = ($samples | Measure-Object -Property working_set_mb  -Maximum).Maximum
    $peakPriv  = ($samples | Measure-Object -Property private_mb     -Maximum).Maximum
    $peakPaged = ($samples | Measure-Object -Property paged_mem_mb   -Maximum).Maximum
}

$allureFiles  = Get-ChildItem -Path $AllureDir -Recurse -File -ErrorAction SilentlyContinue
$allureSizeMb = if ($allureFiles) { [math]::Round(($allureFiles | Measure-Object -Sum Length).Sum/1MB,2) } else { 0 }
$allureCount  = if ($allureFiles) { $allureFiles.Count } else { 0 }

# === 4b. Парсинг Allure result.json — статусы сценариев + сообщения ошибок ===

$resultJsons = Get-ChildItem -Path $AllureDir -Recurse -Filter '*-result.json' -ErrorAction SilentlyContinue
$passed = $failed = $broken = $skipped = 0
$pendingSteps = 0
$errorMessages = New-Object System.Collections.Generic.List[string]

foreach ($r in $resultJsons) {
    try {
        $obj = Get-Content $r.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch { continue }
    switch ($obj.status) {
        'passed'  { $passed++ }
        'failed'  { $failed++; if ($obj.statusDetails.message) { $errorMessages.Add("[$($obj.name)] $($obj.statusDetails.message)") } }
        'broken'  { $broken++; if ($obj.statusDetails.message) { $errorMessages.Add("[$($obj.name)] $($obj.statusDetails.message)") } }
        'skipped' { $skipped++ }
    }
    # Pending: шаги без step-definition (status=='skipped' с textContent 'Pending')
    foreach ($step in $obj.steps) {
        if ($step.status -eq 'skipped' -and $step.statusDetails.message -match 'Pending|не найдена процедура') {
            $pendingSteps++
            $errorMessages.Add("PENDING: $($step.name)")
        }
    }
}

# === 4c. Анализ ЖР / лог-файлов VA ===

$jrLogs = @(
    Join-Path $RepoRoot 'tools\ServiceBases\bench-log.txt'
    Join-Path $RepoRoot 'ServiceBases\bench-log.txt'
    Join-Path $RepoRoot 'tools\ServiceBases\BenchMessages.txt'
)
$jrErrors = 0
foreach ($lp in $jrLogs) {
    if (Test-Path $lp) {
        $content = Get-Content $lp -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            $jrErrors += ([regex]::Matches($content, '(?i)\b(ошибка|exception|failed|сбой)\b')).Count
        }
    }
}

# === 5. Запись в csv ===

# КРИТИЧНО: invariant culture — иначе ToString('F1') на ru-locale пишет запятую '40,5'
# вместо точки '40.5', и csv-разделитель ломает schema.
$inv = [System.Globalization.CultureInfo]::InvariantCulture
$durStr   = $Stopwatch.Elapsed.TotalSeconds.ToString('F1', $inv)
$wsStr    = ([double]$peakWs).ToString('F1', $inv)
$privStr  = ([double]$peakPriv).ToString('F1', $inv)
$pagedStr = ([double]$peakPaged).ToString('F1', $inv)
$sizeStr  = ([double]$allureSizeMb).ToString('F2', $inv)

# Шапка обновляется при изменении формата — если старый csv с другим числом колонок, переименуем
if (Test-Path $ResultsCsv) {
    $firstLine = (Get-Content $ResultsCsv -TotalCount 1)
    if ($firstLine -ne 'run_id,stage,profile,n,duration_sec,peak_ws_mb,peak_private_mb,peak_paged_mb,allure_files,allure_size_mb,passed,failed,broken,skipped,pending_steps,jr_error_lines,exit_code,timestamp') {
        $backup = "$ResultsCsv.old-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Move-Item $ResultsCsv $backup
        Write-Host "[bench] csv schema mismatch, archived old → $backup"
    }
}
if (-not (Test-Path $ResultsCsv)) {
    'run_id,stage,profile,n,duration_sec,peak_ws_mb,peak_private_mb,peak_paged_mb,allure_files,allure_size_mb,passed,failed,broken,skipped,pending_steps,jr_error_lines,exit_code,timestamp' |
        Set-Content $ResultsCsv -Encoding UTF8
}
"$RunId,$StageName,$Profile,$N,$durStr,$wsStr,$privStr,$pagedStr,$allureCount,$sizeStr,$passed,$failed,$broken,$skipped,$pendingSteps,$jrErrors,$exit,$(Get-Date -Format 'o')" |
    Add-Content $ResultsCsv

# Дополнительно: сводный файл ошибок для прогона
if ($errorMessages.Count -gt 0) {
    $errFile = Join-Path $BenchRoot "errors-$RunId.log"
    $errorMessages | Set-Content $errFile -Encoding UTF8
    Write-Host "  errors -> $errFile" -ForegroundColor Yellow
}

Write-Host "`n[bench] === RESULT ===`n  duration       : $($Stopwatch.Elapsed.TotalSeconds.ToString('F1')) sec"
Write-Host "  peak WS        : $peakWs MB"
Write-Host "  peak priv      : $peakPriv MB"
Write-Host "  peak paged     : $peakPaged MB"
Write-Host "  allure         : $allureCount files / $allureSizeMb MB"
Write-Host "  scenarios      : passed=$passed  failed=$failed  broken=$broken  skipped=$skipped"
$pendingColor = if ($pendingSteps -gt 0) { 'Yellow' } else { 'Gray' }
Write-Host "  pending steps  : $pendingSteps" -ForegroundColor $pendingColor
$jrColor = if ($jrErrors -gt 0) { 'Yellow' } else { 'Gray' }
Write-Host "  JR error lines : $jrErrors" -ForegroundColor $jrColor
Write-Host "  exit code      : $exit"
Write-Host "  csv            : $ResultsCsv"

# === 6. Уборка временных файлов (artefacts оставляем) ===

if ($Profile -in 'repro2498','heavy') {
    Remove-Item -Recurse -Force $ProfileFeaturesDir -ErrorAction SilentlyContinue
}
Remove-Item $VBParamsTmp, $BenchRunTmp -ErrorAction SilentlyContinue
