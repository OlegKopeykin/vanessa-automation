# tools/checks/presets/ — test suites

> Пресет = «что я хочу прогнать в этой сессии». Он указывает один или несколько `builds/` для последовательного выполнения.

## Концепция

Текущая система VA уже двухуровневая:
- **Top-level конфиг** (`tools/JSON/Main.json`, `MiddleCheck_8327.json`, `FastCheck_8327.json`, …) — определяет «что выполнить»: список ссылок на VBParams через поле `ВариантыСборок`.
- **VBParams** (`tools/JSON/VBParams8XXX*.json`) — детальная конфигурация одной сборки: версия 1С, путь к 1С, строка подключения к ИБ, фичи, библиотеки, теги.

В новой структуре эти роли разделены физически:
- `presets/` — top-level конфиги (этот каталог)
- `builds/` — детальные параметры одной сборки

## Группировка по типу

```
presets/
├── fast/        ← быстрая проверка на одной платформе (1 сборка)
├── middle/      ← полная PR-проверка (несколько сборок, разные compat-режимы)
├── web/         ← веб-клиент (отдельно из-за специфики)
├── doc/         ← проверка документации
└── main/        ← общий matrix для финального прогона перед релизом
```

**Почему по типу теста, а не по версии?** Потому что lifecycle:
- Добавить новую версию 1С (8.3.28) = добавить 1-2 пресета (`fast/8328-uf.json`, `middle/8328-uf.json`)
- Изменить тип проверки (новый «smoke»-набор) = добавить новую папку `smoke/` с пресетами для всех версий

То есть «тип теста» более стабилен, чем «версия». См. [Q4 в refactor proposal](../../README.md).

## Каталог пресетов (целевой набор после полной миграции)

### `fast/` — быстрая проверка одной платформы

| Пресет | Что внутри | Эквивалент в старом `tools/JSON/` |
|---|---|---|
| `8327-uf.json` | UF на 8.3.27 | `FastCheck_8327.json` |
| `8327-server-uf.json` | Server UF на 8.3.27 | `FastCheck_Server_8327.json` |
| `8.5.1-uf.json` | UF на 8.5.1 | (не существует пока) |

### `middle/` — полная PR-проверка (несколько сборок)

| Пресет | Сборок внутри | Эквивалент |
|---|---|---|
| `8327-uf.json` | 5 (8.3.24, compat-8.2 OF, compat-8.2 UF, 8.3.27 part1, part2) | `MiddleCheck_8327.json` ← **Jenkins primary** |
| `8.5.1-uf.json` | 1 (8.5.1) | `MiddleCheck_851.json` |

### `web/` — веб-клиент

| Пресет | Эквивалент |
|---|---|
| `8327.json` | `WebCheck_8327.json` |

### `doc/` — проверка документации

| Пресет | Эквивалент |
|---|---|
| `default.json` | `CheckDoc.json` |

### `main/` — общий matrix

| Пресет | Сборок | Эквивалент |
|---|---|---|
| `default.json` | 12 (full matrix) | `Main.json` ← `2 CheckBehavior.cmd` |
| `no-web.json` | 10 (без Web и 8.3.21UF) | `MainNoWeb.json` |
| `linux.json` | (Linux subset) | `MainLinux.json` |
| `server.json` | (Server subset) | `MainServer.json` |

## Текущий статус

Наполнены **все основные пресеты**, реально используемые в CI и локально:
- `presets/middle/8327-uf.json` ← **то же что Jenkins дёргает** (через `MiddleCheck_8327_UF.cmd`)
- `presets/fast/8327-uf.json`
- `presets/web/8327.json`
- `presets/doc/default.json`
- `presets/smoke/8327-uf.json` ← **новый pattern** для pre-commit smoke
- `presets/main/default.json` (частично — некоторые builds ещё в старом `tools/JSON/`)
- `presets/main/no-web.json` (частично)

Все JSON — точные функциональные копии существующих в `tools/JSON/`, с теми же путями внутри.

## Формат пресета

Пресет — JSON с двумя обязательными полями:

```json
{
   "КаталогиДляОчистки": [
      "../ServiceBases/allurereport",
      "../ServiceBases/cucumber",
      "../ServiceBases/junitreport"
   ],
   "ВариантыСборок": [
      "../builds/8.3.27/uf-fastcheck.json"
   ]
}
```

- `КаталогиДляОчистки` — что вычистить перед прогоном (Allure-репорт, cucumber, junit). Пути — относительно `tools/`.
- `ВариантыСборок` — массив ссылок на builds. Можно несколько — будут запущены последовательно (как сборки 8.3.6 + 8.3.21 + 8.3.27 в `MiddleCheck_8327.json`).

Опциональные:
- `ЗапускатьWatcher: true` — включает watchdog для отлова зависших сборок.

## Как запустить (целевой синтаксис)

```bash
# Быстрая проверка
oscript tools/checks/check.os fast/8327-uf

# Полная PR-проверка (как Jenkins)
oscript tools/checks/check.os middle/8327-uf

# Главный matrix
oscript tools/checks/check.os main/default

# Список доступных пресетов
oscript tools/checks/check.os --list
```

## Как запустить сейчас (через старый runner)

Пока `check.os` — stub, можно вызвать существующий runner напрямую:

```bash
cd tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\fast\8327-uf.json
```

⚠️ Внимание: пути внутри JSON-пресета могут требовать корректировки относительно текущего CWD. Это одна из причин, почему `check.os` нужен — он будет нормализовать пути.

## Связи

- [`builds/README.md`](../builds/README.md) — про атомарные runs, на которые ссылаются пресеты
- [`platform/README.md`](../platform/README.md) — про ОС-специфичные wrappers
- [`../README.md`](../README.md) — общий обзор `tools/checks/`
