# builds/compat-8.2/ — режим совместимости с 1С 8.2

> Здесь — builds, которые проверяют **режим совместимости с 1С 8.2** на современных платформах. Сама платформа 8.2 не используется (EOL и не установлена), но режим compat-8.2 поддерживается на 8.3.6 (OF) и 8.3.21 (UF).

## Почему `compat-8.2/`, а не `8.2/`

Файлы исторически называются `VBParams82*.json`, но платформа 8.2 физически не запускается. Папка названа `compat-8.2/`, чтобы:
- Не вводить в заблуждение (нет версии 8.2 в установке)
- Сохранить семантику «проверка совместимости с 8.2» из имени
- Отличить от других build-папок, где имя = реальной платформе

## Список builds (целевой)

| Build | Эквивалент | Платформа физического запуска | Используется в |
|---|---|---|---|
| `of-fast.json` | `VBParams82OF_fast.json` | **8.3.6.2530** (32-bit) | `presets/middle/8327-uf.json` ← Jenkins |
| `uf-fast.json` | `VBParams82UF_fast.json` | **8.3.21.1624** (32-bit) | `presets/middle/8327-uf.json` ← Jenkins |
| `of.json` | `VBParams82OF.json` | 8.3.6 | `presets/main/default.json` |
| `uf.json` | `VBParams82UF.json` | 8.3.21 | `presets/main/default.json` |

## Параметры платформ

| Build | Платформа | bin path | Сервисная база |
|---|---|---|---|
| `of-fast`, `of` | 8.3.6.2530 | `C:\Program Files (x86)\1cv8\8.3.6.2530\bin\1cv8.exe` | `v82ServiceBase82` |
| `uf-fast`, `uf` | 8.3.21.1624 | `C:\Program Files (x86)\1cv8\8.3.21.1624\bin\1cv8c.exe` | `v82ServiceBase82` |

Обратите внимание:
- 8.3.6 OF использует `1cv8.exe` (толстый клиент)
- 8.3.21 UF использует `1cv8c.exe` (тонкий клиент)
- Сервисная база общая (`v82ServiceBase82`) — для совместимости

## Активность в CI

**Эта папка — не legacy**, активно используется Jenkins. В каждом PR-check'е (см. `MiddleCheck_8327.json`) запускаются `of-fast` и `uf-fast`. Это **критическая часть** value proposition VA — поддержка обратной совместимости.

⚠️ Не удалять — без этих сборок CI ломается.

## Особенности тестов в compat-режиме

- Тесты с тегом `@IgnoreOn82Builds` (374 файла) пропускаются — они не работают в режиме совместимости
- Тег `@IgnoreOnOFBuilds` (388) пропускается на OF
- Тег `@IgnoreOnUFSovm82Builds` (92) пропускается на UF в режиме sovm-82

## Связи

- [`../README.md`](../README.md) — общий README builds
- [`../../presets/middle/8327-uf.json`](../../presets/middle/8327-uf.json) — Jenkins-пресет ссылается сюда
- [`../../../audits/analysis-2026-04-28-jenkins-ci-pr-check.md`](https://github.com/_/_) — Jenkins inventory (контекст)
