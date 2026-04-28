# presets/middle/ — полная PR-проверка

> Middle = несколько сборок включая compat-режимы. Это **то, что Jenkins дёргает на каждый PR**. Время — десятки минут.

## Что внутри

`middle/8327-uf.json` (целевой эквивалент `tools/JSON/MiddleCheck_8327.json`) — это primary CI gate. Внутри:

| Сборка | Build | Платформа | Назначение |
|---|---|---|---|
| 1 | `builds/8.3.24/uf-installcomponent.json` | 8.3.24.1548 | InstallComponent проверка |
| 2 | `builds/compat-8.2/of-fast.json` | **8.3.6.2530** | Compat 8.2 OF |
| 3 | `builds/compat-8.2/uf-fast.json` | **8.3.21.1624** | Compat 8.2 UF |
| 4 | `builds/8.3.27/uf-middlecheck-part1.json` | 8.3.27.1859 | Основная, часть 1 (тег `@uf-part1`) |
| 5 | `builds/8.3.27/uf-middlecheck-part2.json` | 8.3.27.1859 | Основная, часть 2 (тег `@uf-part2`) |

Разделение на 2 части — для параллельного выполнения и обхода timeout'ов на больших наборах.

## Список пресетов (целевой)

| Пресет | Сборок | Эквивалент | Используется |
|---|---|---|---|
| `8327-uf.json` | 5 | `MiddleCheck_8327.json` | **Jenkins primary** |
| `8.5.1-uf.json` | 1 | `MiddleCheck_851.json` | Локально |

## Чем Middle отличается от Fast

| Аспект | Fast | Middle |
|---|---|---|
| Сборок | 1 | 5 |
| Платформ | 1 (8.3.27) | 4 (8.3.6, 8.3.21, 8.3.24, 8.3.27) |
| Compat-тесты 8.2 | нет | да (OF + UF) |
| Retry на flaky | 1 | 3 |
| Время | ~10-20 мин | десятки минут |
| Запуск | вручную | автоматически Jenkins на каждый PR |

## Как использовать

```bash
# Целевой синтаксис
oscript tools/checks/check.os middle/8327-uf

# Сейчас — через старый runner
cd tools
oscript .\onescript\run-behavior-check-session.os .\JSON\MiddleCheck_8327.json
```

⚠️ Не запускайте middle часто локально — это десятки минут. Для быстрой обратной связи используйте `fast/` или smoke-набор.

## Связи

- [`../README.md`](../README.md) — общий README пресетов
- [`../../builds/8.3.27/`](../../builds/8.3.27/) — основные builds
- [`../../builds/compat-8.2/`](../../builds/compat-8.2/) — compat-builds
- [`../../builds/8.3.24/`](../../builds/8.3.24/) — InstallComponent build
