# platform/linux/ — Linux ОС-обёртки

> Нативные shell-скрипты для Linux: chmod, xdg-open, ffmpeg для скриншотов.

## Файлы (целевой набор)

| Файл | Назначение | Контракт |
|---|---|---|
| `prepare.sh` | Подготовка окружения | `prepare.sh` (без аргументов) |
| `check.sh` | Запуск проверки | `check.sh <effective-preset.json>` |
| `view-allure.sh` | Открытие Allure в браузере (xdg-open) | `view-allure.sh` (без аргументов) |

## Текущий статус

**STATUS: концептуальные stub'ы**. Реальная Linux-машина для тестирования не настроена. Реализация по образцу `tools/linux/2CheckBehavior.sh` и `tools/linux/runtest.sh`.

## Контракт `check.sh`

```bash
#!/bin/sh
set -e

# UTF-8 native в Linux
export LC_ALL=ru_RU.UTF-8
export LANG=ru_RU.UTF-8

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$REPO_ROOT"

# Сборка через compile.sh (если есть) или альтернатива
if [ -f compile.sh ]; then
    sh compile.sh
fi

# Дёрнуть существующий runner
oscript ./tools/onescript/run-behavior-check-session.os "$1"
```

## Hardcoded paths внутри (наследуется из tools/linux/)

- 1С — `/opt/1C/v8.3/<arch>/1cv8` (см. `tools/linux/runtest.sh`)
- Сервисные базы — относительно `tools/ServiceBases/`
- xdg-open для Allure-отчёта

## Linux-окружение в текущей VA

Линукс-сборка поддерживается ограниченно:
- `tools/linux/runtest.sh` — runner с вшитым `oneC_root=/opt/1C/v8.3/x86_64` или `i386`
- `tools/JSON/MainLinux.json` — пресет для Linux (но не пробовал в production)
- В Jenkins (`vanessa.bit-erp.ru`) — пока только Windows-ноды

## Связи

- [`../README.md`](../README.md) — общий README ОС-обёрток
- [`../windows/`](../windows/) — Windows-аналоги
- `tools/linux/` — старая Linux-инфраструктура (до переезда)
