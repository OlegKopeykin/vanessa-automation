# tools/checks/ — структурированные локальные запуски

> **Status: для обсуждения**. Эта структура положена рядом со старыми `tools/*.cmd` и `tools/JSON/`, ничего не ломает. Старые точки входа (например `tools\MiddleCheck_8327_UF.cmd`) продолжают работать.
>
> **Полный набор примеров запуска** — в [EXAMPLES.md](EXAMPLES.md).

## Зачем эта папка

В корне `tools/` сейчас лежит 16 `.cmd`-точек входа (`FastCheck_8327_UF.cmd`, `MiddleCheck_8327_UF.cmd`, …). Каждая — однострочник вида:

```cmd
cd ..
call compile.bat
cd .\tools
oscript .\onescript\run-behavior-check-session.os .\JSON\<имя>.json
```

В `tools/JSON/` — 127 файлов: top-level конфиги (`Main.json`, `MiddleCheck_8327.json`, …) и параметры сборок (`VBParams8XXX*.json`).

Проблемы плоской структуры:
- **Матрица версий 1С разложена в плоский список** — добавить 8.3.28 = 5–10 новых файлов в двух местах.
- **5 разных стилей именования** (`1 PrepareCheck.cmd`, `FastCheck_8327_UF.cmd`, `env-install.cmd`, `MakeDistrib.os`, `run-behavior-check-session.os`).
- **`windows/` vs `linux/` иерархии разъезжаются** — Windows entrypoints в корне, Linux в подпапке.
- **127 JSON в одной куче** — нет видимой структуры по платформе/режиму.
- **Mislabel в именах** — `MiddleCheck_8327_Server_UF.cmd` дёргает `FastCheck_Server_8327.json` (имя обманывает).

## Что предлагается

Зонтик `tools/checks/` с тремя осями:

```
tools/checks/
├── README.md                    ← этот файл
├── EXAMPLES.md                  ← полный набор примеров запуска
│
├── check.os                     ← универсальный entrypoint (oscript check.os <preset>)
├── prepare.os                   ← подготовка окружения
├── view-allure.os               ← просмотр Allure-отчёта
│
├── presets/                     ← test suites (бывшие top-level *Check_*.json)
│   ├── README.md
│   ├── smoke/                   ← 20-30 critical-path сценариев (~5 минут, pre-commit)
│   ├── fast/                    ← быстрые проверки на одной платформе
│   ├── middle/                  ← полные проверки + compat-режимы (Jenkins primary)
│   ├── web/                     ← веб-клиент
│   ├── doc/                     ← проверка документации
│   └── main/                    ← общий matrix (для финального прогона)
│
├── builds/                      ← атомарные runs (бывшие VBParams8XXX*.json)
│   ├── README.md
│   ├── 8.3.27/                  ← по версии платформы
│   ├── 8.3.24/                  ← InstallComponent
│   ├── 8.3.6/                   ← старая платформа (CheckDoc)
│   ├── compat-8.2/              ← compat-режим 8.2 (на платформах 8.3.6, 8.3.21)
│   └── 8.5.1/                   ← новейшая
│
└── platform/                    ← ОС-специфика
    ├── README.md
    ├── windows/                 ← .cmd-обёртки и compile.bat-логика
    └── linux/                   ← .sh-аналоги
```

## Архитектура — три уровня

```
┌────────────────────────────┐
│ presets/<тип>/<пресет>.json│  ← "что я хочу прогнать": ссылка на 1+ builds
└──────────┬─────────────────┘
           │ "ВариантыСборок": [..., ...]
           ▼
┌────────────────────────────┐
│ builds/<версия>/<имя>.json │  ← "как именно прогнать одну сборку": платформа, режим, теги, фичи
└──────────┬─────────────────┘
           │ выполняется через
           ▼
┌────────────────────────────┐
│ check.os (universal)       │  ← OneScript-роутер: валидирует, резолвит, определяет ОС
└──────────┬─────────────────┘
           │ дёргает
           ▼
┌────────────────────────────┐
│ platform/<ОС>/check.{cmd,sh}│  ← нативная ОС-обёртка: compile.bat, paths
└──────────┬─────────────────┘
           │ внутри
           ▼
   tools/onescript/run-behavior-check-session.os <effective.json>
   (существующий runner)
```

## Быстрые примеры

См. [EXAMPLES.md](EXAMPLES.md) для полного набора. Краткий обзор:

| Что нужно | Команда |
|---|---|
| Smoke перед commit (~5 мин) | `oscript tools/checks/check.os smoke/8327-uf` |
| Быстрая проверка локально (~10-20 мин) | `oscript tools/checks/check.os fast/8327-uf` |
| Полная PR-проверка (как Jenkins) | `oscript tools/checks/check.os middle/8327-uf` |
| Веб-клиент | `oscript tools/checks/check.os web/8327` |
| Документация | `oscript tools/checks/check.os doc/default` |
| Полный matrix (релиз, часы) | `oscript tools/checks/check.os main/default` |

## Маппинг старо → ново

| Старый файл | Новый эквивалент |
|---|---|
| `tools\1 PrepareCheck.cmd` | `oscript tools/checks/prepare.os` |
| `tools\2 CheckBehavior.cmd` | `oscript tools/checks/check.os main/default` |
| `tools\2 CheckBehaviorNoWeb.cmd` | `oscript tools/checks/check.os main/no-web` |
| `tools\3 ViewAllureReport.cmd` | `oscript tools/checks/view-allure.os` |
| `tools\CheckDoc.cmd` | `oscript tools/checks/check.os doc/default` |
| `tools\FastCheck_8327_UF.cmd` | `oscript tools/checks/check.os fast/8327-uf` |
| `tools\MiddleCheck_8327_UF.cmd` | `oscript tools/checks/check.os middle/8327-uf` |
| `tools\WebCheck_8327.cmd` | `oscript tools/checks/check.os web/8327` |
| `tools\MiddleCheck_851_UF.cmd` | `oscript tools/checks/check.os middle/8.5.1-uf` |
| (нет аналога) | `oscript tools/checks/check.os smoke/8327-uf` ← **новое: pre-commit smoke** |

## Что наполнено сейчас

**Полностью функциональные пресеты** (можно запускать через старый runner — см. EXAMPLES.md):
- `presets/middle/8327-uf.json` ← **то же что Jenkins дёргает**
- `presets/fast/8327-uf.json`
- `presets/web/8327.json`
- `presets/doc/default.json`
- `presets/smoke/8327-uf.json` (требует пометки `@SmokeFast` на 20-30 .feature)

**Builds**:
- `builds/8.3.27/`: `uf-fastcheck`, `uf.json`, `uf-middlecheck-part1`, `uf-middlecheck-part2`, `web`, `uf-smoke`
- `builds/8.3.24/uf-installcomponent.json`
- `builds/8.3.6/uf-checkdoc.json`
- `builds/compat-8.2/`: `of-fast.json`, `uf-fast.json`

**Полу-работающие** (ссылаются частично на старые JSON в `tools/JSON/`):
- `presets/main/default.json` (12 builds — пока 2 в новой структуре, остальные старые)
- `presets/main/no-web.json` (10 builds — аналогично)

**Реализованы, требуют валидации на winpc** (поведенческий прогон возможен только на машине с 1С):
- `check.os` — роутер: `--list`, `--dry-run`, валидация `ВариантыСборок`, детект ОС, делегирование обёртке. `--list`/`--dry-run` тестируются без 1С.
- `prepare.os`, `view-allure.os` — роутеры (детект ОС → платформенная обёртка)
- `platform/linux/check.sh`, `prepare.sh`, `view-allure.sh` — Linux-обёртки (валидировать на Linux+1С)

**Рабочие**:
- `platform/windows/check.cmd` — ОС-обёртка (CWD runner'а = `tools/`)
- `platform/windows/prepare.cmd`, `view-allure.cmd` — повторяют логику старых `1 PrepareCheck.cmd` / `3 ViewAllureReport.cmd`

## Важно

- **Старые `.cmd` остаются работать**. Эта папка — дополнение, не замена.
- **`tools/JSON/` остаётся неизменным**. Новые `presets/*.json` и `builds/*.json` — копии существующих с теми же путями внутри (1-к-1).
- **`tools/onescript/run-behavior-check-session.os` НЕ переименовывается** — на этот файл много ссылок (CI, документация, скрипты).
- **Эта папка — для обсуждения архитектуры**. Реальная миграция — отдельный шаг.

## Структура подпапок — куда смотреть дальше

| Папка | Что внутри | README |
|---|---|---|
| [`presets/`](presets/) | Test suites (наборы сборок для одной задачи) | [presets/README.md](presets/README.md) |
| [`builds/`](builds/) | Атомарные runs (параметры одной сборки) | [builds/README.md](builds/README.md) |
| [`platform/`](platform/) | ОС-специфичные wrappers (compile, paths) | [platform/README.md](platform/README.md) |
| [`presets/smoke/`](presets/smoke/) | Smoke check (новый pattern) | [presets/smoke/README.md](presets/smoke/README.md) |

## FAQ

**Q: Я могу прямо сейчас запустить `oscript tools/checks/check.os fast/8327-uf`?**
A: Роутер `check.os` реализован, но требует валидации на машине с 1С (winpc). Без 1С уже можно проверить `oscript tools\checks\check.os --list` и `oscript tools\checks\check.os --dry-run fast/8327-uf`. Гарантированно рабочий путь — старый `tools\FastCheck_8327_UF.cmd` или прямой вызов `cd tools && oscript .\onescript\run-behavior-check-session.os .\checks\presets\fast\8327-uf.json` (функционально идентично).

**Q: Если я хочу попробовать новый пресет?**
A: Запустите его через существующий runner — все JSON в `presets/` и `builds/` совместимы:
```cmd
cd tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\<тип>\<пресет>.json
```
См. [EXAMPLES.md](EXAMPLES.md) для конкретных команд.

**Q: Зачем `compat-8.2/` отдельно от `8.3.6/`?**
A: VBParams82*.json исторически называются "8.2", но физически запускаются на платформах 8.3.6 (OF) и 8.3.21 (UF) в режиме совместимости с 8.2. Семантически это «compat-test для 8.2», не «версия 8.2». Имя папки отражает namespace. Папка `8.3.6/` — для НЕ-compat builds на этой платформе (CheckDoc).

**Q: Что такое smoke?**
A: Новый pattern: 20-30 critical-path сценариев для pre-commit feedback (~5 минут). Заполняет gap между FastCheck (~700 сценариев, 10-20 мин) и nothing. Использует whitelist через тег `@SmokeFast` (механизм встроен в VA, не требует patch). Подробности — [presets/smoke/README.md](presets/smoke/README.md).

**Q: Где обсуждать?**
A: Открывайте issue/discussion в репо `Pr-Mex/vanessa-automation` с тегом «proposal: tools restructure». Или комментируйте под PR, который добавит эту папку.
