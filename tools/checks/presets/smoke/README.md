# presets/smoke/ — smoke check для pre-commit feedback

> Smoke = маленький набор critical-path сценариев (20-30) для **быстрой обратной связи перед commit'ом** (~5 минут).

## Зачем нужен smoke

Между `FastCheck` (~700 сценариев, 10-20 мин) и nothing — нет ничего быстрого. Smoke заполняет этот пробел: контрибьютор делает мелкое изменение → запускает smoke → за 5 минут видит «не сломал ли ничего критичного» → делает commit.

## Список пресетов

| Пресет | Что внутри | Цель |
|---|---|---|
| `8327-uf.json` ✅ | 1 build (`uf-smoke.json`) с whitelist `["SmokeFast"]` | Smoke на 8.3.27 UF |

## Механизм отбора — whitelist через тег

В `builds/8.3.27/uf-smoke.json` используется параметр `СписокТеговОтбор`:

```json
"СписокТеговОтбор": ["SmokeFast"]
```

Это **whitelist**: VA запустит **только** сценарии с тегом `@SmokeFast`. Этот механизм встроен в VA (`VanessaAutomation/Ext/ObjectModule.bsl:213-216`) и активно используется в production:
- `VBParams8324UF_InstallComponent.json` → `["InstallComponent"]`
- `VBParams82OF_fast.json` → `["FastCheck"]`
- `VBParams836UFCheckDoc.json` → `["DocumentationBuild"]`

То есть подход **не требует patch'а runner'а** — это уже работает.

## Как пометить сценарий как smoke

Просто добавить тег `@SmokeFast` в .feature перед сценарием:

```gherkin
@tree
@SmokeFast
Функционал: Создание новой фичи через UI
  ...
```

Или на уровне отдельного сценария:

```gherkin
Функционал: Базовые операции с фичами

  @SmokeFast
  Сценарий: Создание новой фичи
    Допустим: я открыл главную форму
    Когда: я нажимаю "Создать"
    Тогда: открывается форма редактирования
```

## Как запустить (целевой синтаксис)

```bash
oscript tools/checks/check.os smoke/8327-uf
```

## Как запустить сейчас (через старый runner)

```cmd
cd tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\smoke\8327-uf.json
```

## Принципы отбора

Какие сценарии помечать `@SmokeFast`:

1. **Critical path** — то, без чего весь продукт не имеет смысла (создание фичи, запуск сценария, отображение результата)
2. **Часто ломается** — сценарии, которые регрессируют чаще всего (по истории git/issue)
3. **Покрывает много** — один сценарий, который трогает несколько систем (форма + JSON + step definitions)
4. **Быстро выполняется** — каждый smoke-сценарий должен быть < 30 секунд

Чего НЕ помечать:
- Edge case'ы и регрессии конкретных багов (для них есть полный регресс)
- Сложные multi-step workflows (для них есть middle)
- Видеоинструкции (помечены `@Video`, исключаются)
- Compat-тесты для 8.2 (для них есть отдельный compat-режим)

## Жизненный цикл

- Раз в квартал — review набора smoke-сценариев
- Если smoke прошёл, а MiddleCheck упал на критичной регрессии — добавить тот сценарий в smoke
- Если smoke стабильно зелёный, а проект «горит» в production — пересмотреть состав

## Связи

- [`../README.md`](../README.md) — общий README пресетов
- [`../../builds/8.3.27/uf-smoke.json`](../../builds/8.3.27/uf-smoke.json) — build с whitelist
- [`../fast/`](../fast/) — для более широкой проверки (700 сценариев)
- [`../middle/`](../middle/) — primary CI gate
