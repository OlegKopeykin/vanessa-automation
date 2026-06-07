# tools/checks/ci — запуск в CI (Jenkins)

[`Jenkinsfile`](Jenkinsfile) — pipeline-as-code для прогона Vanessa Automation через резолвер [`check.os`](../check.os). Проверено на Windows-агенте с 1С 8.3.27 (OneScript 2.0.1, Jenkins 2.555.2).

## Идея

Резолвер не запускает 1С сам — он собирает top-level VBParams (`--out toplevel.json`), а штатный раннер `tools/onescript/run-behavior-check-session.os` запускается отдельной стадией. Так stdout 1С виден в логе Jenkins, а exit-код раннера = статус прогона.

```
check.os --scenario … --platform … --flavor … --feature ./… --out toplevel.json
        │
        ▼
run-behavior-check-session.os toplevel.json   (CWD = tools/)
```

## Параметры джобы

| Параметр | Дефолт | Назначение |
|---|---|---|
| `AGENT_LABEL` | `gui` | агент с интерактивной GUI-сессией (1С рисует окна) |
| `BRANCH` | `feature/tools-checks-preview` | ветка репозитория |
| `REPO_URL` | — | URL git-репо vanessa-automation |
| `GIT_CRED` | — | Jenkins credentials (если репо приватный) |
| `SCENARIO` | `fast` | сценарий (`fast`/`smoke`/`regress`/…) |
| `PLATFORM` | `8.3.27` | версия 1С |
| `FLAVOR` | `uf` | флейвор (`uf`/`of`/`web`/`nosync`/…) |
| `FEATURES` | одна фича | список фич, **по строке, каждая с `./`** (пусто = весь сценарий) |
| `PLATFORM_SEARCH_PATH` | — | корень 1С, если **не** `C:\Program Files\1cv8` (напр. `D:\1cv8`) |

## Требования к агенту

1. 1С:Предприятие нужной версии. Если не в `C:\Program Files\1cv8` — задать `PLATFORM_SEARCH_PATH` (стадия `Localize` перенацелит дескриптор).
2. OneScript (`oscript`) в PATH + библиотеки: `opm install json logos v8runner`.
3. git в PATH; доступ к github.com (стадия `Packages` качает внешние компоненты).
4. **Защита от опасных действий 1С отключена** — иначе `init.epf` виснет на модальном диалоге. В эффективном `conf.cfg` 1С:
   ```
   DisableUnsafeActionProtection=.*
   ```
5. Агент запущен в **интерактивной сессии** (не как служба) — тонкий клиент в TESTMANAGER требует рабочий стол.

## Стадии

`Checkout → [Localize] → Packages → Templates → Compile epf → Clear cache → Clean base → Prepare → Resolve → Test`

- **Checkout** — явным `git` (не git-плагином): `-c http.sslVerify=false` для self-signed, `-c credential.helper=` против зависания Git Credential Manager, идемпотентно к осиротевшему `.git`.
- **Localize** — только если задан `PLATFORM_SEARCH_PATH`.
- **Clean base** — свежая база (`init.epf` прошлого прогона её «пачкает»).
- **Resolve** — `check.os --out` (без запуска 1С).
- **Test** — раннер из `CWD=tools/`.

## Грабли (важное)

| Симптом | Фикс |
|---|---|
| 0 сценариев, BuildStatus=3 | фичи в `FEATURES` **без `./`** — добавить префикс `./features/...` |
| `init.epf` висит | `DisableUnsafeActionProtection=.*` в conf.cfg 1С |
| checkout `SEC_E_WRONG_PRINCIPAL` | self-signed git-сервер → checkout через `bat`+`git -c http.sslVerify=false` (в Jenkinsfile уже так) |
| fetch висит | Git Credential Manager → `-c credential.helper=` (в Jenkinsfile уже так) |
| `POST config.xml` → HTTP 500 при деплое inline-pipeline | голый `&` в скрипте → экранировать `&amp;` или хранить как Jenkinsfile из SCM (рекомендуется) |

## Ограничения

- **dev-лицензия 1С** — лимит одновременных клиентов ИБ. Узкий набор одно-/двухклиентных фич проходит; полный regress с VanessaExt multi-session требует PROF/КОРП.
- **web-флейвор** — нужен веб-сервер + публикация базы (отдельная инфра-настройка).

## Примеры команд резолвера

См. [`../EXAMPLES.md`](../EXAMPLES.md). Сравнение со старым путём (`tools/*.cmd` + `tools/JSON/`): [`../COMPARISON.md`](../COMPARISON.md).
