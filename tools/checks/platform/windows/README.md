# platform/windows/ — Windows ОС-обёртки

> Нативные Windows-скрипты, которые выполняют ОС-специфичные шаги: chcp 65001, compile.bat, IrfanView, VLC.

## Файлы (целевой набор)

| Файл | Назначение | Контракт |
|---|---|---|
| `prepare.cmd` | Подготовка окружения (compile, env-check, package downloads) | `prepare.cmd` (без аргументов) |
| `check.cmd` | Запуск проверки на основе уже разрезолвленного preset JSON | `check.cmd <effective-preset.json>` |
| `view-allure.cmd` | Открытие Allure-отчёта в браузере | `view-allure.cmd` (без аргументов) |

## Контракт `check.cmd`

Принимает 1 аргумент — путь к разрезолвленному preset JSON (с absolute paths). Выполняет:

```cmd
@echo off
chcp 65001 > nul                              :: UTF-8 для русских символов
cd /d %~dp0\..\..\..\..                       :: в корень репо (из tools/checks/platform/windows/)
call compile.bat                              :: сборка cf
cd /d %~dp0\..\..\..\..                       :: возвращаемся в корень
oscript .\tools\onescript\run-behavior-check-session.os %1
exit /b %ERRORLEVEL%
```

⚠️ Текущий `check.cmd` — рабочий пример, но требует тестирования на реальной Windows-машине с 1С.

## Hardcoded paths внутри (наследуется из старых .cmd)

- `compile.bat` — в корне репо, должен быть в PATH или вызываться через `call`
- 1С — `C:\Program Files\1cv8\<версия>\bin\1cv8c.exe` (см. issue про `ONEC_ROOT`)
- IrfanView — `C:\Program Files (x86)\IrfanView\i_view32.exe` (для скриншотов)

## Связь с Jenkins

Текущий Jenkins (`VAPullRequestCheck`) **НЕ дёргает эти обёртки** — он использует старый `tools\MiddleCheck_8327_UF.cmd`. Возможная замена в Jenkins job-config:

```diff
- C:\J3\workspace\VAPullRequestCheck\tools>"MiddleCheck_8327_UF.cmd"
+ C:\J3\workspace\VAPullRequestCheck>oscript .\tools\onescript\run-behavior-check-session.os .\tools\checks\presets\middle\8327-uf.json
```

См. [`../README.md`](../README.md) → раздел «Связь с Jenkins» для подробностей.

## Связи

- [`../README.md`](../README.md) — общий README ОС-обёрток
- [`../linux/`](../linux/) — Linux-аналоги
