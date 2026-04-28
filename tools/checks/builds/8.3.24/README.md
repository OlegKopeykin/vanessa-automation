# builds/8.3.24/ — InstallComponent проверка

> Платформа 8.3.24 используется в Jenkins для проверки InstallComponent (нативная компонента 1С).

## Список builds (целевой)

| Build | Эквивалент | Используется в |
|---|---|---|
| `uf-installcomponent.json` | `VBParams8324UF_InstallComponent.json` | `presets/middle/8327-uf.json` ← **Jenkins** |
| `uf.json` | `VBParams8324UF.json` | `presets/main/default.json` |
| `uf-middlecheck.json` | `VBParams8324UF_MiddleCheck.json` | (для отдельного 8324 middle) |
| `web.json` | `VBParams8324Web.json` | (на будущее) |

## Параметры платформы

- **Версия**: 8.3.24
- **Точная сборка на Jenkins-ноде**: 8.3.24.1548 (`C:\Program Files\1cv8\8.3.24.1548\bin\1cv8c.exe`)
- **Архитектура**: 64-bit (x64)
- **Сервисная база**: `tools/ServiceBases/v83ServiceBase8324`

## Особенности

- Запускается специально для InstallComponent тестов — нативная компонента VanessaExt
- В Jenkins Middle — это первая сборка (validate native перед прогоном на 8.3.27)
- Тег `@IgnoreOn8324` для несовместимых с этой версией сценариев

## Связи

- [`../README.md`](../README.md) — общий README builds
- [`../../presets/middle/8327-uf.json`](../../presets/middle/8327-uf.json) — Jenkins-пресет, ссылается сюда
