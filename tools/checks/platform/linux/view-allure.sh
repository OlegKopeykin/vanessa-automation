#!/bin/sh
# Linux ОС-обёртка для просмотра Allure-отчёта.
# Эквивалент tools/3 ViewAllureReport.cmd для Linux.
# Дёргается из universal router'а tools/checks/view-allure.os
#
# Требует: allure CLI в PATH (https://github.com/allure-framework/allure2) + Java.
# STATUS: требует валидации на Linux-машине.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

REPORT_DIR="$TOOLS_DIR/ServiceBases/allurereport"
if [ ! -d "$REPORT_DIR" ]; then
    echo "[ERROR] Не найден каталог allure-отчёта: $REPORT_DIR. Сначала запустите check."
    exit 1
fi

cd "$REPORT_DIR"
echo "[INFO] Генерация Allure-отчёта"
allure generate --clean ./*
echo "[INFO] Открытие отчёта"
allure open ./allure-report
