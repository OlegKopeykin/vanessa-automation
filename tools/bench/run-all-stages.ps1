<#
.SYNOPSIS
  Запускает все 9 bench-прогонов одного stage'а: 3 профиля × 3 размера.

.PARAMETER StageName
  Имя stage'а — будет записано в bench-results.csv.

.PARAMETER OnlyProfile
  Опционально: ограничить одним профилем (repro2498/heavy/selftest).

.PARAMETER OnlyN
  Опционально: ограничить одним размером (10/20/50).

.PARAMETER MaxWaitSec
  Максимум секунд ожидания, пока 1С/oscript процессы реально завершатся
  между прогонами (вместо фиксированной паузы). Default 15.

.EXAMPLE
  .\run-all-stages.ps1 -StageName baseline
  # 9 прогонов

  .\run-all-stages.ps1 -StageName fix-2498 -OnlyProfile repro2498
  # 3 прогона (10/20/50 на repro2498)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$StageName,
    [string]$OnlyProfile = $null,
    [int]$OnlyN = 0,
    [int]$MaxWaitSec = 15
)

$ErrorActionPreference = 'Stop'
$BenchRoot = $PSScriptRoot
$RunBench  = Join-Path $BenchRoot 'run-bench.ps1'

$profiles = if ($OnlyProfile) { @($OnlyProfile) } else { @('repro2498','heavy','selftest') }
$sizes    = if ($OnlyN -gt 0) { @($OnlyN) } else { @(10, 20, 50) }
$total    = $profiles.Count * $sizes.Count
$current  = 0

Write-Host "[run-all-stages] StageName=$StageName, total runs=$total"
$started = Get-Date

foreach ($p in $profiles) {
    foreach ($n in $sizes) {
        $current++
        Write-Host "`n========== [$current/$total] $p / N=$n ==========" -ForegroundColor Cyan
        & $RunBench -StageName $StageName -Profile $p -N $n
        if ($current -lt $total) {
            # Active wait: ждём пока 1С/oscript завершатся, но не дольше MaxWaitSec
            $waited = 0
            while ($waited -lt $MaxWaitSec) {
                $stuck = Get-Process 1cv8,1cv8c,oscript -EA SilentlyContinue
                if (-not $stuck) { break }
                Start-Sleep -Seconds 1
                $waited++
            }
            if ($waited -eq $MaxWaitSec) {
                Write-Host "[run-all-stages] timeout ${MaxWaitSec}s — 1С/oscript still running, force-killing"
                Stop-Process -Name 1cv8,1cv8c,oscript -Force -EA SilentlyContinue
                Start-Sleep -Seconds 2
            } else {
                Write-Host "[run-all-stages] processes settled in ${waited}s"
            }
        }
    }
}

$elapsed = (Get-Date) - $started
Write-Host "`n[run-all-stages] ALL DONE in $($elapsed.TotalMinutes.ToString('F1')) min"
Write-Host "Results: $(Join-Path $BenchRoot 'bench-results.csv')"
