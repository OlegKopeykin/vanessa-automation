@echo off
:: Windows ОС-обёртка для подготовки окружения.
:: Эквивалент старого "1 PrepareCheck.cmd".
:: Дёргается из universal router'а tools/checks/prepare.os
::
:: STATUS: stub. Реализация по образцу старого "1 PrepareCheck.cmd".

setlocal
chcp 65001 > nul

set "REPO_ROOT=%~dp0..\..\..\.."
cd /d "%REPO_ROOT%" || (
    echo [ERROR] Не удалось перейти в корень репо: %REPO_ROOT%
    exit /b 1
)

:: Поддержка русских имён файлов в git
echo [INFO] Настройка git core.quotepath = false
git config --local core.quotepath false

:: Создание сервисных баз
echo [INFO] Запуск build-service-conf.os
oscript .\tools\onescript\build-service-conf.os
exit /b %ERRORLEVEL%
