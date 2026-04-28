# presets/main/ — общий matrix для финального прогона

> Main = широкий matrix (10-12 сборок: разные платформы 8.3.6 → 8.3.27, 8.2 OF/UF, Web). Используется локально перед релизом для финальной проверки. **В CI не запускается** (Jenkins использует Middle).

## Список пресетов (целевой)

| Пресет | Сборок | Эквивалент | Назначение |
|---|---|---|---|
| `default.json` | 12 | `tools/JSON/Main.json` | Полный matrix (default для `2 CheckBehavior.cmd`) |
| `no-web.json` | 10 | `tools/JSON/MainNoWeb.json` | Без Web и без 8.3.21UF (для машин без браузера) |
| `linux.json` | (Linux subset) | `tools/JSON/MainLinux.json` | Linux-окружение |
| `server.json` | (Server subset) | `tools/JSON/MainServer.json` | Серверные сборки |

## Состав `default.json` (12 сборок)

- 8.3.24 InstallComponent
- 8.3.21 UF noSync
- 8.3.17 UF Sovm 8.2
- 8.2 OF (на платформе 8.3.6)
- 8.2 UF (на платформе 8.3.21)
- 8.3.6 OF
- 8.3.21 UF
- 8.3.22 UF
- 8.3.23 UF
- 8.3.24 UF
- 8.3.27 UF
- 8.3.27 Web

Полный охват — это **часы** работы локально. Используется только перед релизом или при глобальных изменениях.

## Как использовать

```bash
# Целевой синтаксис
oscript tools/checks/check.os main/default

# Сейчас — через старый
cd tools
2 CheckBehavior.cmd
```

## Связи

- [`../README.md`](../README.md) — общий README пресетов
- [`../middle/`](../middle/) — для PR используйте Middle (не Main)
- [`../fast/`](../fast/) — для быстрой проверки используйте Fast
