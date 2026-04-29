<#
.SYNOPSIS
  Проверяет JSON-валидность созданных конфигов и пути в них.
#>
$Diag = Join-Path $PSScriptRoot '_diag'
$BenchRunPath = Join-Path $Diag 'BenchRun.json'
$VBParamsPath = Join-Path $Diag 'VBParams.json'

Write-Host "=== Parse BenchRun.json ==="
try {
    $b = Get-Content $BenchRunPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  parsed OK"
    Write-Host "  КаталогиДляОчистки = $($b.КаталогиДляОчистки -join ' ; ')"
    Write-Host "  ВариантыСборок     = $($b.ВариантыСборок     -join ' ; ')"
    Write-Host "  ЗапускатьWatcher   = $($b.ЗапускатьWatcher)"
} catch {
    Write-Host "  PARSE FAILED: $_"
}

Write-Host "`n=== Parse VBParams.json ==="
try {
    $v = Get-Content $VBParamsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  parsed OK"
    Write-Host "  ИмяСборки      = $($v.ИмяСборки)"
    Write-Host "  КаталогФич     = $($v.КаталогФич)"
    Write-Host "  КаталогOutputAllureБазовый = $($v.КаталогOutputAllureБазовый)"
    Write-Host "  ПутьКVanessaAutomation     = $($v.ПутьКVanessaAutomation)"
} catch {
    Write-Host "  PARSE FAILED: $_"
}

Write-Host "`n=== Existence checks ==="
$paths = @(
    $b.ВариантыСборок | ForEach-Object { $_ }
    $v.КаталогФич
    Join-Path (Split-Path $PSScriptRoot -Parent) (Split-Path $v.ПутьКVanessaAutomation -Leaf)
)
foreach ($p in $paths) {
    Write-Host ("  {0,-90} {1}" -f $p, (if (Test-Path $p) {'EXISTS'} else {'MISSING'}))
}
