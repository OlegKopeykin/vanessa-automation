#!/bin/sh
# Linux ОС-обёртка для подготовки окружения.
# Эквивалент tools/linux/1PrepareCheck.sh (+ git core.quotepath как в Windows-варианте).
# Дёргается из universal router'а tools/checks/prepare.os
#
# STATUS: требует валидации на Linux-машине с установленной 1С.

set -e

export LC_ALL=ru_RU.UTF-8 2>/dev/null || true
export LANG=ru_RU.UTF-8 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Поддержка русских имён файлов в git
cd "$REPO_ROOT"
echo "[INFO] git config core.quotepath false"
git config --local core.quotepath false || true

# Создание сервисных баз. CWD = tools/linux, как у оригинального 1PrepareCheck.sh
# (build-service-conf-linux.os вызывается как ../onescript/...).
cd "$TOOLS_DIR/linux"
echo "[INFO] Запуск build-service-conf-linux.os"
oscript ../onescript/build-service-conf-linux.os
