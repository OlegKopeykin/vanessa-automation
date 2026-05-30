@echo off
:: Windows ОС-обёртка для запуска проверки.
:: Контракт: check.cmd <top-level.json>
::   <top-level.json> — абсолютный путь к top-level JSON (сгенерирован резолвером check.os).
:: Дёргается из tools/checks/check.os, который определяет ОС и подбирает обёртку.

setlocal

:: 1. UTF-8 для корректного отображения русских символов
chcp 65001 > nul

:: 2. Проверяем что аргумент передан
if "%~1"=="" (
    echo [ERROR] Не передан путь к top-level JSON.
    echo Usage: check.cmd ^<absolute-path-to-top-level.json^>
    exit /b 1
)

if not exist "%~1" (
    echo [ERROR] top-level JSON не найден: %~1
    exit /b 1
)

:: 3. Сохраняем путь. REPO_ROOT — для compile.bat, TOOLS_DIR — рабочий каталог runner'а.
::    КРИТИЧНО: runner ОБЯЗАН стартовать с CWD = tools/, иначе сломаются относительные
::    пути в дескрипторах ("./../vanessa-automation.epf" и т.п.).
::    Поэтому: compile в корне, затем cd в tools/, затем запуск runner'а.
set "PRESET=%~1"
set "REPO_ROOT=%~dp0..\..\..\.."
set "TOOLS_DIR=%~dp0..\..\.."

:: 4. Сборка .cf — call compile.bat в корне репо (как в старых .cmd)
cd /d "%REPO_ROOT%" || (
    echo [ERROR] Не удалось перейти в корень репо: %REPO_ROOT%
    exit /b 2
)
echo [INFO] Запуск compile.bat в %CD%
call compile.bat
if errorlevel 1 (
    echo [ERROR] compile.bat завершился с кодом %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

:: 5. Переходим в tools/ и передаём управление существующему OneScript-runner'у
cd /d "%TOOLS_DIR%" || (
    echo [ERROR] Не удалось перейти в tools: %TOOLS_DIR%
    exit /b 2
)
echo [INFO] Запуск run-behavior-check-session.os с top-level %PRESET% (CWD=%CD%)
oscript .\onescript\run-behavior-check-session.os "%PRESET%"
exit /b %ERRORLEVEL%
