# builds/8.3.27/ — основная активная версия

> Все builds для платформы 1С 8.3.27. Это самая свежая версия, используется для всех современных проверок (Fast, Middle, Web, Main).

## Список builds (целевой)

| Build | Эквивалент в `tools/JSON/` | Используется в presets |
|---|---|---|
| **`uf-fastcheck.json`** ✅ (есть рабочий пример) | `VBParams8327UF_FastCheck.json` | `presets/fast/8327-uf.json` |
| `uf-middlecheck-part1.json` | `VBParams8327UF_MiddleCheck_part1.json` | `presets/middle/8327-uf.json` ← Jenkins |
| `uf-middlecheck-part2.json` | `VBParams8327UF_MiddleCheck_part2.json` | `presets/middle/8327-uf.json` ← Jenkins |
| `uf-server-fastcheck.json` | `VBParams8327UF_Server_FastCheck.json` | `presets/fast/8327-server-uf.json` |
| `uf.json` | `VBParams8327UF.json` | `presets/main/default.json` |
| `web.json` | `VBParams8327Web.json` | `presets/web/8327.json` |

## Параметры платформы

- **Версия**: 8.3.27
- **Точная сборка на Jenkins-ноде**: 8.3.27.1859 (`C:\Program Files\1cv8\8.3.27.1859\bin\1cv8c.exe`)
- **Архитектура**: 64-bit (x64)
- **Сервисная база**: `tools/ServiceBases/v83ServiceBase8327`
- **Порт TestClient**: 1538

## Особенности

- На 8.3.27 запускаются и UF (управляемые формы), и серверные конфигурации
- Тесты с тегом `@IgnoreOn8327` пропускаются
- Разделение на `part1`/`part2` через тег `@uf-part2` — для параллелизма Middle на Jenkins
- Самая часто обновляемая папка — при выходе новой минорной версии 1С (8.3.27.XXXX) обновляется `bin`-путь

## Связи

- [`../README.md`](../README.md) — общий README builds
- [`../../presets/fast/8327-uf.json`](../../presets/fast/8327-uf.json) — пример пресета, ссылающегося сюда
