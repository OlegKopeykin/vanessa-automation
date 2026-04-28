# tools/checks/platform/ — ОС-специфичные обёртки

> Здесь живёт всё, что специфично для конкретной ОС: пути к 1С, команды сборки, открытие отчётов, native processes.

## Концепция

Универсальные роутеры (`tools/checks/check.os`, `prepare.os`, `view-allure.os`) — кроссплатформенные. Они определяют ОС и дёргают соответствующий нативный скрипт из этой папки:

```
oscript tools/checks/check.os fast/8327-uf
            ↓
   определяет ОС
            ↓
   дёргает один из:
   ├── platform/windows/check.cmd <effective-config.json>
   └── platform/linux/check.sh   <effective-config.json>
            ↓
   compile.bat / compile.sh
            ↓
   oscript ../onescript/run-behavior-check-session.os <effective-config.json>
```

## Почему ОС-специфика отдельно

Часть подготовки **реально ОС-зависима**, и писать её в OneScript через `СтартПроцесс("cmd /c ...")` неудобно:

| Действие | Windows | Linux |
|---|---|---|
| Сборка `.cf` | `compile.bat` | `compile.sh` |
| Открыть отчёт | `start http://...` | `xdg-open http://...` |
| Скриншот | IrfanView | scrot/gnome-screenshot |
| Видео-запись | VLC через `screen://` | ffmpeg через `:0.0+` |
| Путь к 1С | `C:\Program Files\1cv8\...` | `/opt/1C/v8.3/...` |
| Codepage | `chcp 65001` | (UTF-8 native) |
| `chmod` | n/a | нужен для cf |

Размещение этой логики в нативных bash/cmd-скриптах:
- Удобнее писать и читать (OS admin не должен учить OneScript синтаксис `СтартПроцесс`)
- Легче дебажить (нативные ошибки)
- Расширяется на macOS/WSL добавлением одной папки

## Структура

```
platform/
├── README.md                 ← этот файл
├── windows/
│   ├── README.md
│   ├── prepare.cmd           ← подготовка окружения (compile.bat, env-check)
│   ├── check.cmd             ← запуск проверки (cd, compile, oscript runner)
│   └── view-allure.cmd       ← открытие Allure-отчёта в браузере
└── linux/
    ├── README.md
    ├── prepare.sh
    ├── check.sh
    └── view-allure.sh
```

## Контракт между роутером и обёрткой

Роутер `check.os` вызывает:

```
platform/<ОС>/check.{cmd|sh} <путь к effective preset JSON>
```

Где `<путь>` — уже разрезолвенный пресет (с absolute paths, проверенный на существование).

Обёртка обязана:
1. `chcp 65001` (Windows) — для русских символов
2. `cd ../..` (выйти из `tools/checks/platform/<ОС>/` в корень репо)
3. `call compile.bat` или `./compile.sh` — собрать `.cf`
4. `cd tools/checks` (вернуться)
5. Передать управление: `oscript ../onescript/run-behavior-check-session.os <effective-config.json>`
6. Вернуть exit code из oscript

Exit code 0 = success, ненулевой = ошибка. Роутер пробрасывает его наружу.

## Связь с Jenkins

Jenkins на `vanessa.bit-erp.ru` сейчас дёргает корневой `tools\MiddleCheck_8327_UF.cmd` напрямую. Этот `.cmd` НЕ через эту папку — он обращается к `tools\onescript\run-behavior-check-session.os` со старыми путями.

**Что это значит:**

1. Эта папка `platform/` не попадает в Jenkins-pipeline автоматически — её нужно явно подключить через изменение Jenkins job-config.
2. Старый `tools/MiddleCheck_8327_UF.cmd` остаётся работать как есть.
3. Возможный путь миграции:
   - Новая структура работает локально (через эту папку)
   - Jenkins job обновляется: `call MiddleCheck_8327_UF.cmd` → `oscript tools\checks\check.os middle/8327-uf` (или эквивалент через ОС-обёртку)
   - После soak-периода — старый `MiddleCheck_8327_UF.cmd` можно удалить

Полный inventory всех Jenkins jobs полезен до любых удалений — могут быть другие jobs (`VANightlyCheck`, `VARelease`, ...), которые дёргают другие `.cmd`/JSON по их именам.

## Текущий статус превью

Сейчас в этой папке:
- README на каждом уровне
- 1 рабочий пример: `windows/check.cmd` — прозрачный wrapper, демонстрирующий контракт
- Stub'ы для остальных команд

Не реализовано:
- `linux/*.sh` — концептуальные stub'ы, реальный Linux-окружение для тестирования отсутствует
- `view-allure.cmd` / `view-allure.sh` — нужны нативные команды открытия браузера

## Как запустить сейчас

Поскольку роутеры (`check.os`) — пока stub, можно временно дёргать обёртки напрямую:

```cmd
:: Windows
tools\checks\platform\windows\check.cmd tools\checks\presets\fast\8327-uf.json
```

```bash
# Linux (когда будет реализован)
tools/checks/platform/linux/check.sh tools/checks/presets/fast/8327-uf.json
```

Но **рекомендация — использовать старые `.cmd` из корня `tools/`** до полной готовности новой инфраструктуры.

## Связи

- [`windows/README.md`](windows/README.md) — детали Windows-обёрток
- [`linux/README.md`](linux/README.md) — детали Linux-обёрток
- [`../README.md`](../README.md) — общий обзор `tools/checks/`
