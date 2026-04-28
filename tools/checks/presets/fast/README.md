# presets/fast/ — быстрые проверки на одной платформе

> Fast = одна сборка, обычно последняя версия 1С, без compat-режимов. Используется для локальной быстрой обратной связи (`~10-20 минут`).

## Семантика

«Fast» в контексте VA означает **«быстрее по окружению»** (1 сборка вместо 5), но **не «маленький набор тестов»**. По охвату тестов FastCheck почти равен MiddleCheck — оба исключают только `@IgnoreOnCIMainBuild`, `@Ignore` и т.д. Из 1163 .feature только 2 имеют тег `@IgnoreOnFastCheck`.

Если нужен **smoke-набор из 20-30 сценариев** (~5 минут) — см. отдельный pattern с `СписокТеговОтбор: ["SmokeFast"]`. Это другая сущность, чем FastCheck.

## Список пресетов (целевой)

| Пресет | Что выполняет | Эквивалент |
|---|---|---|
| **`8327-uf.json`** | UF на 8.3.27 ✅ (есть рабочий пример) | `tools/JSON/FastCheck_8327.json` |
| `8327-server-uf.json` | Server UF на 8.3.27 | `tools/JSON/FastCheck_Server_8327.json` |
| `8.5.1-uf.json` | UF на 8.5.1 (на будущее) | (не существует) |

## Как использовать

```bash
# Целевой синтаксис (после реализации check.os)
oscript tools/checks/check.os fast/8327-uf

# Сейчас — через старый runner напрямую
cd tools
oscript .\onescript\run-behavior-check-session.os .\checks\presets\fast\8327-uf.json
```

## Связи

- [`../README.md`](../README.md) — общий README пресетов
- [`../../builds/8.3.27/`](../../builds/8.3.27/) — куда ссылаются эти пресеты
