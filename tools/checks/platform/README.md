# tools/checks/platform/ — ОС-специфичные обёртки

Универсальные роутеры (`check.os`, `prepare.os`, `view-allure.os`) определяют ОС и передают управление нативному скрипту из этой папки.

## Структура

```
platform/
├── windows/
│   ├── check.cmd         # запуск проверки (compile.bat → run-behavior-check-session.os)
│   ├── prepare.cmd       # подготовка окружения
│   └── view-allure.cmd   # открытие Allure-отчёта
└── linux/
    ├── check.sh
    ├── prepare.sh
    └── view-allure.sh
```

## Контракт

Резолвер `check.os` вызывает:

```
platform/<ОС>/check.{cmd|sh} <абсолютный-путь-к-top-level.json>
```

Обёртка обязана:
1. Запустить `compile.bat` / `compile.sh` в корне репозитория.
2. Перейти в `tools/` (CWD обязателен — runner резолвит пути от него).
3. Запустить `oscript .\onescript\run-behavior-check-session.os <top-level.json>`.
4. Вернуть exit code.

## Добавить ОС

Создать папку `platform/<ос>/`, скопировать и адаптировать `check.cmd`/`check.sh`. Обёртка получает единственный аргумент — абсолютный путь к top-level JSON.
