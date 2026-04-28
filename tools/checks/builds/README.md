# tools/checks/builds/ — атомарные runs

> Build = «как именно прогнать одну сборку»: версия 1С, путь к платформе, строка подключения к ИБ, фичи, теги, retries.

## Концепция

В старой структуре эти конфиги называются `VBParams8XXX*.json` (Variant of Build Params) и лежат в `tools/JSON/` плоской кучей (~110 файлов).

В новой структуре они физически сгруппированы по версии платформы:

```
builds/
├── 8.3.27/         ← основная активная (в Jenkins)
├── 8.3.24/         ← InstallComponent (в Jenkins)
├── compat-8.2/     ← compat-режим 8.2 (запуск на 8.3.6 OF и 8.3.21 UF)
└── 8.5.1/          ← новейшая, в Jenkins не использовалась (на момент анализа)
```

## Группировка по версии — почему

**Lifecycle-аргумент**: добавить новую версию платформы (например 8.3.28) = одна папка `builds/8.3.28/` с 1-4 build-конфигами, без расползания по всей `tools/JSON/`.

**Retire-аргумент**: убрать поддержку версии (например, когда 8.3.21 окончательно EOL) = удалить одну папку, не охотиться по плоской куче.

**Альтернатива** — группировка по типу (`builds/uf/`, `builds/server/`, `builds/web/`) — отвергнута, потому что версия меняется чаще, чем тип.

## Особый случай — `compat-8.2/`

Файлы `tools/JSON/VBParams82*.json` (исторически "8.2") **физически запускаются на платформах 8.3.6 (OF) и 8.3.21 (UF)** в режиме совместимости с 8.2. Это критическая часть VA — поддержка обратной совместимости, активно используется Jenkins (см. `MiddleCheck_8327.json` → 5 сборок включая `VBParams82OF_fast.json` на 8.3.6).

Папка названа `compat-8.2/`, потому что:
- Имя `8.2/` ввело бы в заблуждение (платформа 8.2 не запускается, она EOL и не установлена)
- Имя `8.3.6/` и `8.3.21/` неудобно для тех, кто ищет «где compat 8.2»

## Каталог builds (целевой набор)

### `8.3.27/` — основная активная

| Build | Эквивалент в `tools/JSON/` | Используется в |
|---|---|---|
| `uf-fastcheck.json` | `VBParams8327UF_FastCheck.json` | `presets/fast/8327-uf.json` |
| `uf-middlecheck-part1.json` | `VBParams8327UF_MiddleCheck_part1.json` | `presets/middle/8327-uf.json` ← Jenkins |
| `uf-middlecheck-part2.json` | `VBParams8327UF_MiddleCheck_part2.json` | `presets/middle/8327-uf.json` ← Jenkins |
| `uf-server-fastcheck.json` | `VBParams8327UF_Server_FastCheck.json` | `presets/fast/8327-server-uf.json` |
| `uf.json` | `VBParams8327UF.json` | `presets/main/default.json` |
| `web.json` | `VBParams8327Web.json` | `presets/web/8327.json` |

### `8.3.24/` — InstallComponent

| Build | Эквивалент | Используется в |
|---|---|---|
| `uf-installcomponent.json` | `VBParams8324UF_InstallComponent.json` | `presets/middle/8327-uf.json` ← Jenkins |
| `uf.json` | `VBParams8324UF.json` | `presets/main/default.json` |
| `uf-middlecheck.json` | `VBParams8324UF_MiddleCheck.json` | (для отдельного 8324 middle) |
| `web.json` | `VBParams8324Web.json` | (на будущее) |

### `compat-8.2/` — compat 8.2 на разных платформах

| Build | Эквивалент | Платформа физического запуска | Используется в |
|---|---|---|---|
| `of-fast.json` | `VBParams82OF_fast.json` | 8.3.6.2530 | `presets/middle/8327-uf.json` ← Jenkins |
| `uf-fast.json` | `VBParams82UF_fast.json` | 8.3.21.1624 | `presets/middle/8327-uf.json` ← Jenkins |
| `of.json` | `VBParams82OF.json` | 8.3.6 | `presets/main/default.json` |
| `uf.json` | `VBParams82UF.json` | 8.3.21 | `presets/main/default.json` |

### `8.5.1/`

| Build | Эквивалент |
|---|---|
| `uf-middlecheck.json` | `VBParams851UF_MiddleCheck.json` |

## Текущий статус

В этой папке наполнены **builds, реально используемые в CI и локально**:
- `8.3.27/`: `uf-fastcheck`, `uf`, `uf-middlecheck-part1`, `uf-middlecheck-part2`, `web`, `uf-smoke`
- `8.3.24/uf-installcomponent.json`
- `8.3.6/uf-checkdoc.json`
- `compat-8.2/of-fast.json`, `uf-fast.json`

Все 9 builds — **точные функциональные копии** соответствующих VBParams в `tools/JSON/`, с теми же путями внутри (1-к-1).

Остальные ~100 VBParams (для редких/legacy сценариев) пока остаются в `tools/JSON/` — могут быть смигрированы по мере необходимости.

## Формат build

```json
{
   "ИмяСборки": "Сборка 8.3.27 UF FastCheck",
   "ВерсияПлатформы": "8.3.27",
   "КаталогПоискаВерсииПлатформы": "C:\\Program Files\\1cv8",
   "СтрокаПодключенияКБазе": "ENTERPRISE /F.\\ServiceBases\\v83ServiceBase8327",
   "EpfДляИнициализацияБазы": "./epf/init.epf",
   "ПараметрыДляИнициализацияБазы": "./epf/init.json",
   "ПутьКVanessaAutomation": "./../vanessa-automation.epf",
   "КаталогФич": "./features",
   "КаталогиБиблиотек": ["./features/Libraries"],
   ...
   "СписокТеговИсключение": ["IgnoreOnCIMainBuild", "IgnoreOnFastCheck", "Ignore", "Video"]
}
```

Все поля задокументированы в [`tools/JSON/README.md`](../../JSON/README.md). Формат не меняется — меняется только физическое расположение и имена.

## Важные параметры

### Фильтрация тестов

| Параметр | Что делает |
|---|---|
| `СписокТеговИсключение` | blacklist по тегам (используется сейчас) |
| `СписокТеговОтбор` | **whitelist** по тегам (используется в smoke-check) |
| `СписокСценариевДляВыполнения` | конкретные сценарии по имени |
| `СписокФичДляВыполнения` | конкретные .feature-файлы |

### Надёжность

| Параметр | Дефолт | FastCheck | MiddleCheck |
|---|---|---|---|
| `КоличествоПопытокВыполненияСценария` | 1 | 1 | 3 (flaky retry) |
| `КоличествоПопытокВыполненияДействия` | — | 10 | 10 |
| `КоличествоСекундПоискаОкна` | — | 120 | 120 |

### Hardcoded paths (см. [issue про ONEC_ROOT](https://github.com/Pr-Mex/vanessa-automation/issues))

| Что | Где | Сейчас |
|---|---|---|
| Путь к 1С | `КаталогПоискаВерсииПлатформы` | `C:\\Program Files\\1cv8` (Windows hardcoded) |
| IrfanView | `КомандаСделатьСкриншот` | `C:\\Program Files (x86)\\IrfanView\\i_view32.exe` |
| VLC | `ЗаписьВидеоКомандаНачатьЗаписьВидео` | `C:\\Program Files (x86)\\VideoLAN\\VLC\\vlc.exe` |
| 1С для генерации EPF | `ВерсияПлатформыДляГенерацииEPF` | `C:/Program Files (x86)/1cv8/8.3.10.2772/bin` |

После миграции в новую структуру эти пути остаются как есть (миграция структуры ≠ исправление hardcoded). Параметризация — отдельный трек (см. issue про `ONEC_ROOT`).

## Как build связан с пресетом

Пример из `presets/middle/8327-uf.json`:

```json
{
   "КаталогиДляОчистки": [...],
   "ВариантыСборок": [
      "../builds/8.3.24/uf-installcomponent.json",
      "../builds/compat-8.2/of-fast.json",
      "../builds/compat-8.2/uf-fast.json",
      "../builds/8.3.27/uf-middlecheck-part1.json",
      "../builds/8.3.27/uf-middlecheck-part2.json"
   ]
}
```

Пресет = orchestrator. Build = atomic unit.

## Связи

- [`presets/README.md`](../presets/README.md) — что такое пресеты и как они ссылаются на builds
- [`platform/README.md`](../platform/README.md) — где живут ОС-обёртки
- [`tools/JSON/README.md`](../../JSON/README.md) — описание полей VBParams (исходный документ — формат не меняется)
