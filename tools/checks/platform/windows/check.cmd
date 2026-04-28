@echo off
:: Windows ОС-обёртка для запуска проверки.
:: Контракт: check.cmd <effective-preset.json>
::   <effective-preset.json> — абсолютный путь к разрезолвенному пресет-JSON
:: Дёргается из universal router'а tools/checks/check.os, который
:: определяет ОС и подбирает правильный platform/<ОС>/check.cmd|sh
::
:: STATUS: рабочий пример, требует тестирования на Windows с установленной 1С.

setlocal

:: 1. UTF-8 для корректного отображения русских символов
chcp 65001 > nul

:: 2. Проверяем что аргумент передан
if "%~1"=="" (
    echo [ERROR] Не передан путь к preset JSON.
    echo Usage: check.cmd ^<absolute-path-to-preset.json^>
    exit /b 1
)

if not exist "%~1" (
    echo [ERROR] Preset не найден: %~1
    exit /b 1
)

:: 3. Сохраняем путь, переходим в корень репо
set "PRESET=%~1"
set "REPO_ROOT=%~dp0..\..\..\.."
cd /d "%REPO_ROOT%" || (
    echo [ERROR] Не удалось перейти в корень репо: %REPO_ROOT%
    exit /b 2
)

:: 4. Сборка .cf — call compile.bat (как в старых .cmd)
echo [INFO] Запуск compile.bat в %CD%
call compile.bat
if errorlevel 1 (
    echo [ERROR] compile.bat завершился с кодом %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

:: 5. Передаём управление существующему OneScript-runner'у
echo [INFO] Запуск run-behavior-check-session.os с пресетом %PRESET%
oscript .\tools\onescript\run-behavior-check-session.os "%PRESET%"
exit /b %ERRORLEVEL%
