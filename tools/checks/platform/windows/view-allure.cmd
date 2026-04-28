@echo off
:: Windows ОС-обёртка для просмотра Allure-отчёта.
:: Эквивалент старого "3 ViewAllureReport.cmd".
:: Дёргается из universal router'а tools/checks/view-allure.os
::
:: Требует:
::   - allure.bat в PATH (https://github.com/allure-framework/allure2/releases)
::   - Java (нужна для allure)
::
:: STATUS: stub. Реализация по образцу старого "3 ViewAllureReport.cmd".

setlocal
chcp 65001 > nul

set "REPO_ROOT=%~dp0..\..\..\.."
cd /d "%REPO_ROOT%\tools\ServiceBases\allurereport" || (
    echo [ERROR] Не найден каталог allure-отчёта. Сначала запустите check.
    exit /b 1
)

echo [INFO] Генерация Allure-отчёта
call allure generate --clean .\*
if errorlevel 1 exit /b %ERRORLEVEL%

echo [INFO] Открытие отчёта в браузере
call allure open .\allure-report
exit /b %ERRORLEVEL%
