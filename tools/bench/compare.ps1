<#
.SYNOPSIS
  Сравнение двух stage'ей по метрикам из bench-results.csv.

.PARAMETER Baseline
  Имя baseline-stage (например, "baseline").

.PARAMETER Candidate
  Имя candidate-stage (например, "fix-2498").

.PARAMETER ThresholdPct
  Порог регрессии в процентах (default 5).

.EXAMPLE
  .\compare.ps1 -Baseline baseline -Candidate fix-2498
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$Baseline,
    [Parameter(Mandatory=$true)] [string]$Candidate,
    [int]$ThresholdPct = 5
)

$ErrorActionPreference = 'Stop'
$ResultsCsv = Join-Path $PSScriptRoot 'bench-results.csv'
if (-not (Test-Path $ResultsCsv)) { throw "Не найден $ResultsCsv" }

$rows = Import-Csv $ResultsCsv
$base = $rows | Where-Object { $_.stage -eq $Baseline }
$cand = $rows | Where-Object { $_.stage -eq $Candidate }

if (-not $base) { throw "Нет строк для stage '$Baseline'" }
if (-not $cand) { throw "Нет строк для stage '$Candidate'" }

# Усредняем по profile+n (если несколько прогонов одного варианта)
$baseAvg = $base | Group-Object profile,n | ForEach-Object {
    [PSCustomObject]@{
        profile = $_.Group[0].profile
        n       = [int]$_.Group[0].n
        ws      = [double]($_.Group | Measure-Object peak_ws_mb       -Average).Average
        priv    = [double]($_.Group | Measure-Object peak_private_mb  -Average).Average
        paged   = [double]($_.Group | Measure-Object peak_paged_mb    -Average).Average
        time    = [double]($_.Group | Measure-Object duration_sec     -Average).Average
        allure  = [double]($_.Group | Measure-Object allure_size_mb   -Average).Average
    }
}
$candAvg = $cand | Group-Object profile,n | ForEach-Object {
    [PSCustomObject]@{
        profile = $_.Group[0].profile
        n       = [int]$_.Group[0].n
        ws      = [double]($_.Group | Measure-Object peak_ws_mb       -Average).Average
        priv    = [double]($_.Group | Measure-Object peak_private_mb  -Average).Average
        paged   = [double]($_.Group | Measure-Object peak_paged_mb    -Average).Average
        time    = [double]($_.Group | Measure-Object duration_sec     -Average).Average
        allure  = [double]($_.Group | Measure-Object allure_size_mb   -Average).Average
    }
}

Write-Host "Сравнение: $Baseline → $Candidate (threshold ±${ThresholdPct}%)`n"
$header = '{0,-12} {1,4} {2,12} {3,12} {4,12} {5,12} {6,12}' -f 'profile','N','ws_mb','priv_mb','time_s','allure_mb','status'
Write-Host $header
Write-Host ('-' * $header.Length)

$regressions = 0
foreach ($key in ($baseAvg | ForEach-Object { "$($_.profile)/$($_.n)" } | Sort-Object -Unique)) {
    $p, $n = $key -split '/'
    $b = $baseAvg | Where-Object { $_.profile -eq $p -and $_.n -eq [int]$n } | Select-Object -First 1
    $c = $candAvg | Where-Object { $_.profile -eq $p -and $_.n -eq [int]$n } | Select-Object -First 1
    if (-not $c) { continue }

    function Pct($baseV, $candV) {
        if ($baseV -eq 0) { return '—' }
        return ('{0:+0.0}%/{1:0.0}%' -f (($candV-$baseV)/$baseV*100), ([Math]::Abs(($candV-$baseV)/$baseV*100)))
    }
    function Ratio($baseV, $candV) {
        if ($baseV -eq 0) { return '—' }
        return [math]::Round(($candV-$baseV)/$baseV*100, 1)
    }

    $wsPct    = Ratio $b.ws    $c.ws
    $privPct  = Ratio $b.priv  $c.priv
    $timePct  = Ratio $b.time  $c.time
    $alluPct  = Ratio $b.allure $c.allure

    $status = if ([Math]::Abs($wsPct) -gt $ThresholdPct -or [Math]::Abs($timePct) -gt $ThresholdPct) {
        if ($wsPct -gt 0 -or $timePct -gt 0) { $regressions++; 'REGRESSION' } else { 'IMPROVED' }
    } else { 'OK' }

    '{0,-12} {1,4} {2,5}/{3,+5}% {4,5}/{5,+5}% {6,5}/{7,+5}% {8,5}/{9,+5}% {10}' -f `
        $p, $n,
        ([int]$c.ws),    $wsPct,
        ([int]$c.priv),  $privPct,
        ([int]$c.time),  $timePct,
        ([int]$c.allure),$alluPct,
        $status | Write-Host
}

Write-Host "`nИтог: $regressions регрессий выше порога ${ThresholdPct}%"
exit $regressions
