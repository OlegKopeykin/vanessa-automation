<#
.SYNOPSIS
  Diagnostic helper для отладки bench-инфраструктуры.
  Создаёт постоянные конфиги в tools/bench/_diag/, не удаляет временные файлы,
  запускает oscript и пишет полный лог в _diag/run.log.

.NOTES
  Не запускается в обычном bench-цикле — только для ручного дебага.
#>
[CmdletBinding()]
param(
    [string]$Profile = 'repro2498',
    [int]$N = 10
)

$ErrorActionPreference = 'Stop'
$BenchDir = $PSScriptRoot
$ToolsDir = Resolve-Path (Join-Path $BenchDir '..')
$RepoRoot = Resolve-Path (Join-Path $BenchDir '..\..')
$Diag     = Join-Path $BenchDir '_diag'
New-Item -ItemType Directory -Force -Path $Diag | Out-Null
$AllureDir = Join-Path $Diag 'allure'
New-Item -ItemType Directory -Force -Path $AllureDir | Out-Null

# Изоляция фичи (один файл)
$FeatDir = Join-Path $Diag 'features'
if (Test-Path $FeatDir) { Remove-Item $FeatDir -Recurse -Force }
New-Item -ItemType Directory -Path $FeatDir | Out-Null
Copy-Item (Join-Path $BenchDir "$Profile\$N.feature") $FeatDir

# Считаем относительные пути от tools/ — substring подход, не требует существования target
function Get-RelativePath([string]$base, [string]$target) {
    $b = (([System.IO.Path]::GetFullPath($base)).TrimEnd('\') + '\').ToLower()
    $t = [System.IO.Path]::GetFullPath($target)
    if ($t.ToLower().StartsWith($b)) {
        return '.\' + $t.Substring($b.Length)
    }
    return $t  # не подкаталог — возвращаем абсолютный
}

# Используем абсолютные пути — Vanessa может запускать 1С из разных рабочих каталогов,
# относительные `.\` ломаются. Encoding-проблема (которая раньше путала с абсолютными) уже починена.
$AllureDirAbs   = [System.IO.Path]::GetFullPath($AllureDir)
$FeatDirAbs     = [System.IO.Path]::GetFullPath($FeatDir)
$VBParamsPath   = Join-Path $Diag 'VBParams.json'
$VBParamsAbs    = [System.IO.Path]::GetFullPath($VBParamsPath)

# Для JSON: backslash экранируется как \\
function Json-Escape-Path([string]$p) { return $p.Replace('\','\\') }

# КРИТИЧНО: Get-Content без -Encoding UTF8 в PS 5.1 читает UTF-8 BOM как cp1251, ломая кириллицу.
$VBParamsTpl = Get-Content (Join-Path $BenchDir 'configs\VBParams_template.json') -Raw -Encoding UTF8
$VBParams = $VBParamsTpl.Replace('__FEATURES_DIR_REL__', (Json-Escape-Path $FeatDirAbs)).Replace('__ALLURE_DIR_REL__', (Json-Escape-Path $AllureDirAbs))
[System.IO.File]::WriteAllText($VBParamsPath, $VBParams, [System.Text.UTF8Encoding]::new($true))

$BenchRunTpl = Get-Content (Join-Path $BenchDir 'configs\BenchRun.json') -Raw -Encoding UTF8
$BenchRun = $BenchRunTpl.Replace('__VBPARAMS_PATH_REL__', (Json-Escape-Path $VBParamsAbs)).Replace('__ALLURE_DIR_REL__', (Json-Escape-Path $AllureDirAbs))
$BenchRunPath = Join-Path $Diag 'BenchRun.json'
[System.IO.File]::WriteAllText($BenchRunPath, $BenchRun, [System.Text.UTF8Encoding]::new($true))

Write-Host "=== absolute paths ==="
Write-Host "  AllureDirAbs   = $AllureDirAbs"
Write-Host "  FeatDirAbs     = $FeatDirAbs"
Write-Host "  VBParamsAbs    = $VBParamsAbs"

Write-Host "`n=== BenchRun.json ==="
Get-Content $BenchRunPath

Write-Host "`n=== running oscript (from $ToolsDir) ==="
$LogPath = Join-Path $Diag 'run.log'
Push-Location $ToolsDir
try {
    # cmd.exe pipe → файл, без прохождения через PS текстовых потоков (избегаем UTF-16-кашу)
    $cmd = "oscript onescript\run-behavior-check-session.os `"$BenchRunPath`" > `"$LogPath`" 2>&1"
    cmd /c $cmd
    Write-Host "exit=$LASTEXITCODE"
    Write-Host "log saved: $LogPath"
} finally {
    Pop-Location
}
