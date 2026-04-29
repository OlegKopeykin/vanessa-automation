<#
.SYNOPSIS
  Запуск oscript на ЗАВЕДОМО рабочем конфиге MiddleCheck_8327.json,
  чтобы понять — проблема в нашем конфиге или вообще в окружении.
  Дополнительно проверяет, какие байты пишет Set-Content -Encoding UTF8.
#>
$Repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Existing = Join-Path $Repo 'tools\JSON\MiddleCheck_8327.json'

Write-Host "=== first 10 bytes of MiddleCheck_8327.json (existing, working) ==="
[System.IO.File]::ReadAllBytes($Existing)[0..9] -join ' '

$Mine = Join-Path $PSScriptRoot '_diag\BenchRun.json'
if (Test-Path $Mine) {
    Write-Host "`n=== first 10 bytes of _diag\BenchRun.json (mine) ==="
    [System.IO.File]::ReadAllBytes($Mine)[0..9] -join ' '
}

Write-Host "`n=== running oscript on EXISTING working config (NO ACTUAL TESTS — just first error if any) ==="
Push-Location (Join-Path $Repo 'tools')
try {
    & oscript onescript\run-behavior-check-session.os $Existing 2>&1 | Select-Object -First 30
} finally {
    Pop-Location
}
