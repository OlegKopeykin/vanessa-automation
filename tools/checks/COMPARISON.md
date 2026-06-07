# tools/checks — текущая реализация vs новая (резолвер)

Сравнение **текущего** способа запуска проверок (`tools/*.cmd` + `tools/JSON/*.json` + прямой вызов `run-behavior-check-session.os`) и **нового** (`tools/checks/check.os` — резолвер на дескрипторах).

Обе реализации сейчас сосуществуют в дереве `tools/` (новая — additive, ничего из старого не удалено), поэтому сравнивать можно бок о бок.

---

## Числа

| | Текущее (`tools/*.cmd` + `tools/JSON/`) | Новое (`tools/checks/`) |
|---|---|---|
| Точек входа | **15** `.cmd` | 1 CLI: `check.os` |
| Файлов конфигурации | **128** JSON в `tools/JSON/` (топ-левел + ~80 `VBParams_*`) | **19** дескрипторов (1 defaults + 6 platforms + 6 flavors + 6 scenarios) |
| Размер одного VBParams | ~100 строк, ~40 полей **дублируются в каждом** | поля раскладываются по слоям, дубля нет |
| Добавить платформу | новый `.cmd` + топ-JSON + N×`VBParams_*` (по флейворам/частям) | **1 файл** `platforms/X.json` |
| Сменить путь установки 1С | править `КаталогПоискаВерсииПлатформы` в каждом VBParams | один раз в `platforms/X.json` (или CLI/Localize-оверрайд) |
| Фильтрация сценариев | только negative (`СписокТеговИсключение`) внутри VBParams | positive (`selectTags`) **∪** negative, композиция scenario+platform+flavor |
| Запуск по тегам / одной фиче | нет (только готовые наборы) | `--tags "@X"`, `--feature ./...` |
| Просмотр набора без запуска | нет | `--dry-run`, `--list` |
| Linux | только generic `.sh` | `platform/linux/*` симметрично windows |

---

## Как это выглядит на одном прогоне

### Текущее — MiddleCheck 8.3.27 UF

`tools/MiddleCheck_8327_UF.cmd`:
```bat
cd ..
call compile.bat
cd .\tools
oscript .\onescript\run-behavior-check-session.os .\JSON\MiddleCheck_8327.json
```

`tools/JSON/MiddleCheck_8327.json` (топ-левел) перечисляет готовые VBParams:
```json
{
  "КаталогиДляОчистки": [".\\ServiceBases\\allurereport", ".\\ServiceBases\\cucumber", ".\\ServiceBases\\junitreport"],
  "ЗапускатьWatcher": true,
  "ВариантыСборок": [
    ".\\JSON\\VBParams8327UF_MiddleCheck_part1.json",
    ".\\JSON\\VBParams8327UF_MiddleCheck_part2.json",
    "… part3 … part6"
  ]
}
```

Каждый `VBParams8327UF_MiddleCheck_partN.json` — ~100 строк, где ~40 полей (Allure, таймауты, клиенты, output-каталоги) **скопированы** из части в часть; отличается в основном `СписокТеговИсключение` (ручная разбивка на части).

### Новое — то же самое

```bash
oscript tools/checks/check.os --scenario regress --platform 8.3.27 --flavor uf
```

Резолвер:
1. `build = merge(defaults.json, platforms/8.3.27.json, flavors/uf.json)`
2. применяет `scenarios/regress.json` (теги отбора/исключения, split на части)
3. собирает top-level + VBParams **в памяти** (или `--out` в файл) и зовёт тот же `run-behavior-check-session.os`.

Те же ~40 общих полей лежат **один раз** в `defaults.json`; специфика версии — в `platforms/8.3.27.json`; специфика клиента — в `flavors/uf.json`.

---

## Что НЕ изменилось (намеренно)

- **Раннер** `tools/onescript/run-behavior-check-session.os` — без правок (резолвер просто кормит его готовым top-level).
- **`vanessa-automation.epf`** — без правок; используются штатные `СписокТеговОтбор`/`СписокТеговИсключение`/`СписокФичДляВыполнения`.
- **Платформенные обёртки** `platform/{windows,linux}/*` — тонкие, логики не несут.
- Старые `.cmd`/`JSON` остаются рабочими — миграция additive, можно переключаться постепенно.

---

## Совместимость и проверка эквивалентности

Сверить, что резолвер даёт тот же VBParams, что и старый файл:
```bash
# новое — собрать без запуска
oscript tools/checks/check.os --scenario regress --platform 8.3.27 --flavor uf --dry-run

# и сравнить ключевые поля с tools/JSON/VBParams8327UF_MiddleCheck_part1.json
```

Поля `ВерсияПлатформы`, `КаталогФич`, `КлиентыТестирования`, теги отбора/исключения должны совпадать.

---

## Итог

Текущая реализация — **explicit, но не масштабируется**: каждая комбинация = отдельные файлы с копипастом; матрица платформ × флейворов × частей растёт мультипликативно (128 JSON).

Новая — **композиция вместо копипаста**: N платформ + M флейворов + K сценариев описываются `N+M+K` файлами, а любая их комбинация собирается резолвером в рантайме. Плюс — отбор по тегам/фичам, `--dry-run`, `--out` для CI, симметричный Linux.
