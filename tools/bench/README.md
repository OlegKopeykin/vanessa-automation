# tools/bench/ — bench-инфраструктура для VA-StreamingReports

Замеры пиковой памяти / времени / размера отчётов на 3 профилях × 3 размерах = 9 прогонов на каждый stage перехода на streaming-архитектуру отчётов.

## Файлы

| Путь | Назначение |
|---|---|
| `run-bench.ps1` | Один прогон. Параметры `-StageName -Profile -N`. Запускает семплер памяти 1C-процессов и ждёт окончания прогона |
| `run-all-stages.ps1` | Оркестратор: 9 прогонов одного stage'а подряд |
| `compare.ps1` | Сравнение двух stage'ей по `bench-results.csv`, выводит diff% по метрикам |
| `diff-allure.ps1` | Snapshot-сравнение двух каталогов `allure-results` (для Stage 5+ верификации двойной записи) |
| `configs/VBParams_template.json` | Шаблон VBParams (`__FEATURES_DIR__`/`__ALLURE_DIR__` подменяются) |
| `configs/BenchRun.json` | Шаблон конфига для `run-behavior-check-session.os` |
| `repro2498/` | Синтетический цикл с переменными — репро жалобы #2498 |
| `heavy/` | Тяжёлые значения переменных + накопительный буфер строк |
| `selftest/` | Конфиги для подвыборки из существующих self-tests с минимальной зависимостью от UI |

## Теги Gherkin

Все bench-фичи — `@bench`. Для смоук-варианта (быстрая валидация инфры, ~30 сек на репрезентативный кейс) — `@smoke`:

| Файл | Теги |
|---|---|
| `repro2498/10.feature` | `@bench @smoke @repro2498 @N10 @StreamingReports` |
| `repro2498/{20,50}.feature` | `@bench @repro2498 @N{20,50} @StreamingReports` (без `@smoke`) |
| `heavy/10.feature` | `@bench @smoke @heavy @N10 @StreamingReports` |
| `heavy/{20,50}.feature` | `@bench @heavy @N{20,50} @StreamingReports` (без `@smoke`) |

Запуск только смоук — через тег-фильтр VA или просто `run-bench.ps1 -Profile repro2498 -N 10` (изолированный прогон одного файла).

## Профили

- **repro2498** — `И пока выражение '$Counter$ < N' истинно я выполняю` + создание уникальных переменных. Бьёт по аккумулятору `ОбъектКонтекстСохраняемый` и блоку `ВсеПеременныеШага` (Form:32096-32140).
- **heavy** — то же, но со значениями ~100-150 байт каждое и накопительным буфером — имитирует реальный регрессионный сценарий по нагрузке на память.
- **selftest** — подвыборка из `features/Core/Variables/`, `RegExp/`, `ExecuteCode/`, `ExpectedSomething/`, `FixtureJSONLoad/`, `Translate/`, `KnownSteps/`, `CheckSteps/`, `ErrorDetails/`, `ErrorJson/` — ближе всего к реальной нагрузке без зависимостей от тест-клиента.

## Использование

**ВАЖНО:** требуется PowerShell **7+** (`pwsh`), не Windows PowerShell 5.1 — последний ломает кириллицу в JSON-шаблонах из-за cp1251 default codepage. На win-машине `pwsh.exe` обычно лежит в `C:\Users\<user>\AppData\Local\Microsoft\WindowsApps\pwsh.exe` (приходит с Windows Store / winget).

**ВАЖНО:** требуется **interactive RDP-сессия** — `1cv8c.exe` test-client поднимает GUI-окна. Через headless SSH 1С виснет молча.

```powershell
# 1. Зайти в worktree feat/streaming-reports на winpc через RDP
cd D:\01_GIT\va-streaming

# 2. Сначала компилируем VA (при первом запуске после pull)
.\compile.bat

# 3. Прогон 9 замеров текущего stage'а — через pwsh!
pwsh -ExecutionPolicy Bypass -File .\tools\bench\run-all-stages.ps1 -StageName baseline

# 4. После следующего stage'а — сравнение
pwsh -ExecutionPolicy Bypass -File .\tools\bench\run-all-stages.ps1 -StageName fix-2498
pwsh -ExecutionPolicy Bypass -File .\tools\bench\compare.ps1 -Baseline baseline -Candidate fix-2498

# Smoke на одном прогоне (для валидации инфры):
pwsh -ExecutionPolicy Bypass -File .\tools\bench\_diag.ps1
```

## Очистка зависших процессов (если что-то застряло)

```powershell
Stop-Process -Name 1cv8,1cv8c,oscript,ras,ragent -Force -ErrorAction SilentlyContinue
Remove-Item C:\temp\watcher.json -Force -ErrorAction SilentlyContinue
Remove-Item D:\01_GIT\va-streaming\ServiceBases\v83ServiceBaseBench -Recurse -Force -ErrorAction SilentlyContinue
```

## Метрики в `bench-results.csv`

| Колонка | Что |
|---|---|
| `run_id` | Уникальный id прогона |
| `stage` | Имя stage'а из `-StageName` |
| `profile` | repro2498 / heavy / selftest |
| `n` | 10 / 20 / 50 |
| `duration_sec` | Время прогона |
| `peak_ws_mb` | Пиковая Working Set RAM (всех 1cv8/oscript-процессов) |
| `peak_private_mb` | Пиковая Private (приватная, без shared) |
| `peak_paged_mb` | Пиковая Paged Memory (виртуальная, включая swap) |
| `allure_files` | Кол-во файлов в каталоге `allure-results` |
| `allure_size_mb` | Суммарный размер `allure-results` |
| `exit_code` | Код выхода `oscript run-behavior-check-session.os` |
| `timestamp` | ISO-8601 |

## Семплер

Параллельный PowerShell-job опрашивает `Get-Process` каждые 250 мс (можно поменять `-SamplerIntervalMs`). Ловит процессы с именами `1cv8`, `1cv8c`, `oscript`. Все семплы — в `$env:TEMP\memsamples-<runId>.csv`, по окончании прогона из них считаются пики.

## Контракт регрессии

`compare.ps1` возвращает exit-code равным числу регрессий >5%. Используется в Jenkins-job `va-streaming-bench` для fail-fast.

## Что НЕ делает

- Не запускает компиляцию VA — это ответственность `compile.bat` (пользователь сам перед первым прогоном на новом коммите).
- Не чистит artifact'ы старых прогонов — `tools\ServiceBases\bench-allure-*` накапливаются. Чистить вручную или скриптом.
- Не запускает GUI test-client — наши repro2498/heavy не требуют UI. Selftest требует — только то, что выбрано из low-dep features.

## Связь с проектом

Полный план — `~/git/va/...` (worktree) или `Obsidian: 10-Projects/VA-StreamingReports/`.
