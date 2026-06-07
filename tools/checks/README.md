# tools/checks — резолвер проверок

`check.os` собирает конфигурацию прогона из дескрипторов (defaults / platforms / flavors / scenarios) и запускает существующий runner `run-behavior-check-session.os` через платформенную обёртку.

> Доп. документы: [EXAMPLES.md](EXAMPLES.md) — примеры команд · [COMPARISON.md](COMPARISON.md) — сравнение с текущим путём (`tools/*.cmd` + `tools/JSON/`) · [ci/](ci/) — запуск в Jenkins (Jenkinsfile + инструкция).

## Структура каталога

```
tools/checks/
├── check.os               # резолвер — точка входа
├── prepare.os             # подготовка окружения (→ platform/<ос>/prepare.{cmd,sh})
├── view-allure.os         # открыть Allure-отчёт (→ platform/<ос>/view-allure.{cmd,sh})
│
├── defaults.json          # общие поля VBParams (~40 штук: Allure, скриншоты, таймауты, output-каталоги…)
├── platforms/             # что зависит от версии 1С
│   ├── 8.3.27.json
│   ├── 8.3.24.json
│   ├── 8.3.6.json
│   ├── 8.5.1.json
│   ├── compat-8.2-uf.json # режим совместимости 8.2, управляемые формы (платформа 8.3.21)
│   └── compat-8.2-of.json # режим совместимости 8.2, обычные формы (платформа 8.3.6)
├── flavors/               # что зависит от типа клиента/режима
│   ├── uf.json            # тонкий клиент (управляемые формы)
│   ├── web.json           # веб-клиент
│   ├── of.json            # толстый клиент (обычные формы)
│   ├── nosync.json        # асинхронный режим
│   ├── uf-nosync.json     # composite: uf + nosync
│   └── video.json         # запись видео прогонов (opt-in)
├── scenarios/             # что гонять (теги отбора, исключения, combos)
│   ├── smoke.json
│   ├── fast.json
│   ├── regress.json
│   ├── web.json
│   ├── doc.json
│   └── install-component.json
│
└── platform/              # ОС-обёртки (не менять логику)
    ├── windows/check.cmd
    ├── windows/prepare.cmd
    ├── windows/view-allure.cmd
    ├── linux/check.sh
    ├── linux/prepare.sh
    └── linux/view-allure.sh
```

## Запуск

Запускается из корня репозитория:

```
oscript tools/checks/check.os <флаги>
```

### Основные примеры

```bash
# Smoke на 8.3.27 UF
oscript tools/checks/check.os --scenario smoke --platform 8.3.27 --flavor uf

# FastCheck на 8.3.27 UF
oscript tools/checks/check.os --scenario fast --platform 8.3.27 --flavor uf

# Regress на двух платформах, двух флейворах (матрица 2×2 = 4 сборки)
oscript tools/checks/check.os --scenario regress --platform 8.3.27,8.5.1 --flavor uf,web

# Конкретная фича на 8.3.27 UF
oscript tools/checks/check.os --feature features/Core/mytest.feature --platform 8.3.27 --flavor uf

# По тегу, без watcher
oscript tools/checks/check.os --tags "@InstallComponent" --platform 8.3.24 --flavor uf --no-watcher

# Явные пары (непрямоугольный набор)
oscript tools/checks/check.os --scenario regress --build 8.3.27:uf --build 8.3.27:web --build 8.5.1:uf

# Проверка документации (combos определены в scenarios/doc.json)
oscript tools/checks/check.os --scenario doc

# Посмотреть что соберётся, не запуская
oscript tools/checks/check.os --scenario smoke --platform 8.3.27 --flavor uf --dry-run

# Список доступных сценариев/платформ/флейворов
oscript tools/checks/check.os --list
```

## Алгоритм резолвера

1. Разобрать CLI-аргументы → определить ячейки `(platform, flavor)`.
2. Для каждой ячейки: `build = merge(defaults.json, platforms/<p>.json, flavors/<f>.json)`.
3. Применить сценарий: `СписокТеговОтбор = scenario.selectTags ∪ --tags`; `СписокТеговИсключение = scenario.baseExclude ∪ platform.platformExcludeTags ∪ flavor.flavorExcludeTags`.
4. Записать каждый build во временный VBParams.json.
5. Собрать top-level JSON `{ КаталогиДляОчистки, ЗапускатьWatcher, ВариантыСборок:[...] }`.
6. Передать top-level в платформенную обёртку → runner гоняет сборки последовательно.

## Контракт CWD

Обёртка `platform/<ос>/check.{cmd,sh}` обязана запускать runner с `CWD = tools/`. Все пути в дескрипторах (`ПутьКVanessaAutomation`, `КаталогФич` и др.) — относительно `tools/`. Нарушение CWD = падение прогона.

## Подготовка окружения

```
oscript tools/checks/prepare.os
```

## Просмотр отчёта

```
oscript tools/checks/view-allure.os
```
