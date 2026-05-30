#!/bin/sh
# Linux ОС-обёртка для запуска проверки.
# Контракт: check.sh <top-level.json>
#   <top-level.json> — абсолютный путь к top-level JSON (сгенерирован резолвером check.os).
# Дёргается из tools/checks/check.os. Реализация по образцу tools/linux/runtest.sh.

set -e

# UTF-8 (для русских символов)
export LC_ALL=ru_RU.UTF-8 2>/dev/null || true
export LANG=ru_RU.UTF-8 2>/dev/null || true

# Проверка аргумента
if [ -z "$1" ]; then
    echo "[ERROR] Не передан путь к top-level JSON."
    echo "Usage: check.sh <absolute-path-to-top-level.json>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "[ERROR] top-level JSON не найден: $1"
    exit 1
fi

PRESET="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Сборка (если есть compile.sh) — в корне репо
cd "$REPO_ROOT"
if [ -f compile.sh ]; then
    echo "[INFO] Запуск compile.sh"
    sh compile.sh
fi

# КРИТИЧНО: runner стартует с CWD = tools/, иначе сломаются относительные
# пути в дескрипторах ("./../vanessa-automation.epf" и т.п.).
cd "$TOOLS_DIR"
echo "[INFO] Запуск run-behavior-check-session.os с top-level $PRESET (CWD=$PWD)"
oscript ./onescript/run-behavior-check-session.os "$PRESET"
