# tools/checks/ — примеры использования

> Полный набор сценариев запуска проверок, от smoke (5 минут) до полного matrix (часы).

## Quick reference

| Что нужно | Команда (целевая) | Команда (сейчас, через старый runner) |
|---|---|---|
| Smoke перед commit | `oscript tools/checks/check.os smoke/8327-uf` | `oscript .\tools\onescript\run-behavior-check-session.os .\tools\checks\presets\smoke\8327-uf.json` |
| Быстрая проверка локально | `oscript tools/checks/check.os fast/8327-uf` | `oscript .\tools\onescript\run-behavior-check-session.os .\tools\checks\presets\fast\8327-uf.json` |
| Полная PR-проверка (как в Jenkins) | `oscript tools/checks/check.os middle/8327-uf` | `oscript .\tools\onescript\run-behavior-check-session.os .\tools\checks\presets\middle\8327-uf.json` |
| Веб-клиент | `oscript tools/checks/check.os web/8327` | `oscript .\tools\onescript\run-behavior-check-session.os .\tools\checks\presets\web\8327.json` |
| Документация | `oscript tools/checks/check.os doc/default` | `oscript .\tools\onescript\run-behavior-check-session.os .\tools\checks\presets\doc\default.json` |
| Полный matrix (релиз) | `oscript tools/checks/check.os main/default` | `oscript .\tools\onescript\run-behavior-check-session.os .\tools\checks\presets\main\default.json` |
| Подготовка окружения | `oscript tools/checks/prepare.os` | `tools\1 PrepareCheck.cmd` |
| Просмотр Allure-отчёта | `oscript tools/checks/view-allure.os` | `tools\3 ViewAllureReport.cmd` |

> ⚠️ Роутер `check.os` реализован, но ещё не валидирован на машине с 1С. Без 1С проверяемы `check.os --list` и `check.os --dry-run <preset>`. Если поведенческий прогон через `check.os` не пошёл — используйте колонку «через старый runner» (функционально идентично).

## Сценарий 1: Pre-commit smoke (рекомендуемый workflow)

**Когда использовать**: после мелкого изменения, перед `git commit`.

**Цель**: за 5 минут понять, не сломал ли я ничего критичного.

```cmd
:: Один раз — пометить 20-30 critical-path сценариев тегом @SmokeFast в .feature
:: Например в features/Core/MainForm/CreateFeature.feature:
::    @tree
::    @SmokeFast
::    Функционал: Создание новой фичи через UI

:: Потом — каждый раз перед commit:
cd C:\path\to\vanessa-automation\tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\smoke\8327-uf.json

:: Если зелёный — commit. Если красный — фикс перед commit.
```

**Время**: ~5 минут.

## Сценарий 2: Быстрая локальная проверка (FastCheck)

**Когда использовать**: после крупного изменения, перед push в свой fork.

**Цель**: прогнать ~700 сценариев на одной платформе (8.3.27 UF) с базовыми ignored-тегами. Без compat-режимов 8.2 — это уже Middle.

```cmd
cd C:\path\to\vanessa-automation\tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\fast\8327-uf.json
```

**Время**: ~10-20 минут.

## Сценарий 3: Полная PR-проверка перед открытием PR (Middle)

**Когда использовать**: перед `gh pr create`. Это то, что Jenkins будет делать на ваш PR — так что лучше прогнать заранее.

```cmd
cd C:\path\to\vanessa-automation\tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\middle\8327-uf.json
```

Запустит **5 сборок**:
1. 8.3.24 InstallComponent (whitelist `@InstallComponent`)
2. 8.3.6 sovm 8.2 OF (whitelist `@FastCheck`)
3. 8.3.21 sovm 8.2 UF (whitelist `@FastCheck`, `@FastCheckUF`)
4. 8.3.27 UF part1 (исключает `@uf-part2`)
5. 8.3.27 UF part2 (исключает `@uf-part1`)

**Время**: десятки минут (зависит от ноды). На Jenkins-ноде Bit-Erp — порядка 30-60 мин.

## Сценарий 4: Только веб-клиент

**Когда использовать**: после изменений в веб-специфичной логике (BrowserSettings, Web tags, JS bridge).

```cmd
cd C:\path\to\vanessa-automation\tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\web\8327.json
```

Запустит сценарии в реальном браузере, исключая `@IgnoreOnWeb` (381 файл).

## Сценарий 5: Документация

**Когда использовать**: после изменений в документации (`docs/`, snippets, примеры).

```cmd
cd C:\path\to\vanessa-automation\tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\doc\default.json
```

Запустит только сценарии с тегом `@DocumentationBuild`.

## Сценарий 6: Финальный прогон перед релизом (Main)

**Когда использовать**: перед мажорным релизом. **Часы работы**, не делать «just because».

```cmd
cd C:\path\to\vanessa-automation\tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\main\default.json
```

**12 сборок**: full coverage всех живых платформ + compat 8.2 OF/UF + Web. Эквивалент `2 CheckBehavior.cmd`.

## Сценарий 7: Запуск отдельного build напрямую

Иногда нужно прогнать **только одну сборку** без обвязки top-level пресета (например, для дебага). Можно вызвать build напрямую:

```cmd
:: НЕ через пресет (без КаталогиДляОчистки и без watcher), а напрямую build
cd C:\path\to\vanessa-automation\tools
oscript .\onescript\run-behavior-check-session.os .\checks\builds\8.3.27\uf-fastcheck.json
```

Минус — нет автоматической очистки `ServiceBases/allurereport/` (старые отчёты будут смешаны). Используйте только для дебага.

## Сценарий 8: Подготовка окружения с нуля

**Когда использовать**: на новой машине, перед первым прогоном.

```cmd
cd C:\path\to\vanessa-automation\tools
1 PrepareCheck.cmd
```

Это создаст сервисные базы (`v83ServiceBase8327`, `v82ServiceBase82`, и т.д.) через `oscript .\onescript\build-service-conf.os`.

## Сценарий 9: Просмотр Allure-отчёта после прогона

```cmd
cd C:\path\to\vanessa-automation\tools
3 ViewAllureReport.cmd
```

Откроет браузер с отчётом. Требует `allure` в PATH (https://github.com/allure-framework/allure2).

## Сценарий 10: Свой собственный набор сценариев (ad-hoc)

Можно сделать одноразовый build-конфиг с конкретным списком .feature:

```json
// my-build.json
{
   "ИмяСборки": "Мой ad-hoc набор",
   "ВерсияПлатформы": "8.3.27",
   "КаталогФич": "./features",
   "СписокФичДляВыполнения": [
      "./features/Core/MainForm/CreateFeature.feature",
      "./features/Core/Behavior/RunScenario.feature"
   ],
   "_остальные_поля": "как в uf-fastcheck.json"
}
```

И preset для него:

```json
// my-preset.json
{
   "КаталогиДляОчистки": [".\\ServiceBases\\allurereport"],
   "ВариантыСборок": [".\\my-build.json"]
}
```

Запуск:
```cmd
oscript .\onescript\run-behavior-check-session.os .\my-preset.json
```

## Сценарий 11: Запуск только сценариев по конкретному тегу

Если хочется прогнать «только UF1_-сценарии» без создания полноценного smoke-набора:

Сделать копию `builds/8.3.27/uf-fastcheck.json` и заменить `СписокТеговИсключение` на `СписокТеговОтбор`:

```json
{
   "...все остальные поля как в uf-fastcheck.json...",
   "СписокТеговОтбор": ["UF1_"]
}
```

Это запустит только ~67 сценариев с тегом `@UF1_`.

## Сценарий 12: Параллельный прогон Linux и Windows

На Linux-машине:
```bash
cd /path/to/vanessa-automation/tools
oscript ./onescript/run-behavior-check-session.os ./checks/presets/main/no-web.json
```

(Windows + Linux могут идти параллельно на разных машинах.)

## Troubleshooting

### `oscript` не найден

Установить OneScript:
```cmd
:: Windows: скачать с https://oscript.io/
:: Или через choco:
choco install onescript
```

### `compile.bat` не найден

Запускайте из корня репо или используйте `tools\1 PrepareCheck.cmd`, который сам делает `cd`.

### `1cv8.exe` не найден

Платформа 1С не установлена в `C:\Program Files\1cv8\<версия>` (или 32-bit аналог). Установить нужную версию или поправить параметр `КаталогПоискаВерсииПлатформы` в build-JSON.

### Allure пустой

Проверить, что:
1. `КаталогиДляОчистки` в пресете включает `.\ServiceBases\allurereport`
2. `ДелатьОтчетВФорматеАллюр: "Истина"` в build
3. Сборки реально завершились (смотреть `ServiceBases/log*.txt`)

### Сценарии не запускаются (0 found)

Скорее всего ошибка в `СписокТеговОтбор` или `СписокТеговИсключение`:
- Whitelist `СписокТеговОтбор` — оставит ТОЛЬКО сценарии с этими тегами. Если ни один не имеет — будет 0.
- Например `["SmokeFast"]` пустой если ни одна .feature не помечена `@SmokeFast`.

Проверить:
```cmd
grep -r "@SmokeFast" features\ --include="*.feature" | wc -l
```

### `СписокФичДляВыполнения` ничего не находит

Пути в `СписокФичДляВыполнения` — относительно `КаталогФич`. Если `КаталогФич: "./features"`, то ссылки должны быть как `./features/Core/...` (с префиксом).

### Test client (тонкий) не подключается

Проверить порт: `ПортЗапускаТестКлиента: "1538"` — занят? Проверить:
```cmd
netstat -ano | findstr :1538
```

## Связи

- [`README.md`](README.md) — общий обзор `tools/checks/`
- [`presets/README.md`](presets/README.md) — концепция пресетов
- [`builds/README.md`](builds/README.md) — концепция builds
- [`platform/README.md`](platform/README.md) — ОС-специфика
- [`presets/smoke/README.md`](presets/smoke/README.md) — детали smoke-механизма
