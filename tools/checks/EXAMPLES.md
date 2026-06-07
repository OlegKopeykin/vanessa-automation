# tools/checks — примеры команд

## Smoke (быстрая проверка, ~5 минут)

```bash
oscript tools/checks/check.os --scenario smoke --platform 8.3.27 --flavor uf
```

## FastCheck (полный набор без @IgnoreOnFastCheck, без retry)

```bash
oscript tools/checks/check.os --scenario fast --platform 8.3.27 --flavor uf
oscript tools/checks/check.os --scenario fast --platform 8.3.27 --flavor uf --no-watcher
```

## Regress (полный набор, retry=3)

```bash
# Одна платформа, один флейвор (на UF → part1/part2, две сборки в одном прогоне)
oscript tools/checks/check.os --scenario regress --platform 8.3.27 --flavor uf

# Две платформы — последовательно
oscript tools/checks/check.os --scenario regress --build 8.3.27:uf --build 8.5.1:uf

# Матрица 2×2 (4 сборки)
oscript tools/checks/check.os --scenario regress --platform 8.3.27,8.5.1 --flavor uf,web
```

## Конкретная фича

```bash
# ВАЖНО: путь фичи — с префиксом ./ (иначе VA не найдёт фичу → 0 сценариев → BuildStatus=3)
oscript tools/checks/check.os --feature ./features/Core/component.feature --platform 8.3.27 --flavor uf
```

## Несколько конкретных фич

```bash
# Каждая фича — отдельный --feature (запятая НЕ разбивается), каждая с ./
oscript tools/checks/check.os --scenario fast --platform 8.3.27 --flavor uf \
  --feature ./features/Core/ExecuteCode/ExecuteCode.feature \
  --feature ./features/Core/OpenForm/ОткрытиеФормы.feature \
  --feature ./features/Core/TestClient/ЗакрытиеОкна.feature --no-watcher
```

## CI-режим: резолв и запуск раздельно (--out)

```bash
# 1) собрать top-level VBParams без запуска 1С
oscript tools/checks/check.os --scenario fast --platform 8.3.27 --flavor uf \
  --feature ./features/Core/ExecuteCode/ExecuteCode.feature --no-watcher --out ./toplevel.json

# 2) запустить раннер напрямую (CWD = tools/) — stdout виден в CI, exit-код = статус
cd tools && oscript ./onescript/run-behavior-check-session.os ../toplevel.json
```

Готовый Jenkins-pipeline на этой схеме: [`ci/Jenkinsfile`](ci/Jenkinsfile), инструкция: [`ci/README.md`](ci/README.md).

## По тегу (ad-hoc)

```bash
oscript tools/checks/check.os --tags "@InstallComponent" --platform 8.3.24 --flavor uf
oscript tools/checks/check.os --tags "@SmokeFast @MyNewTest" --platform 8.3.27 --flavor uf --no-watcher
```

## Несколько платформ (непрямоугольно)

```bash
# UF на 8.3.27 + UF на 8.5.1 + Web на 8.3.27
oscript tools/checks/check.os --scenario regress --build 8.3.27:uf --build 8.5.1:uf --build 8.3.27:web
```

## Явные combos из сценария

```bash
# scenarios/web.json уже содержит combos: [{platform: "8.3.27", flavor: "web"}]
oscript tools/checks/check.os --scenario web

# scenarios/doc.json содержит combos: [{platform: "8.3.6", flavor: "uf"}]
oscript tools/checks/check.os --scenario doc
```

## Compat-8.2

```bash
oscript tools/checks/check.os --scenario fast --platform compat-8.2-uf --flavor uf
oscript tools/checks/check.os --scenario fast --platform compat-8.2-of --flavor of
```

## Подготовка окружения

```bash
oscript tools/checks/prepare.os
```

## Просмотр Allure-отчёта

```bash
oscript tools/checks/view-allure.os
```

## Dry-run (проверить конфигурацию без запуска)

```bash
oscript tools/checks/check.os --scenario regress --platform 8.3.27 --flavor uf --dry-run
oscript tools/checks/check.os --build 8.3.27:uf --build 8.5.1:web --dry-run
```

## Отключить Watcher (для коротких локальных прогонов)

```bash
oscript tools/checks/check.os --scenario smoke --platform 8.3.27 --flavor uf --no-watcher
```

## Список доступных описателей

```bash
oscript tools/checks/check.os --list
```
