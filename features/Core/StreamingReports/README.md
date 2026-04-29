# features/Core/StreamingReports/

Self-tests новой streaming-архитектуры отчётов (`feat/streaming-reports`).

## Структура (наполняется по stage'ам)

```
StreamingReports/
├── EventBus/                  ← Stage 4: pub/sub, изоляция ошибок, отписка
├── AttachmentStore/           ← Stage 3: save, get, dedup, missing hash
├── EventLog/                  ← Stage 4: append, read, iterate
├── PluginDiscovery/           ← Stage 4: активация, ошибка в плагине
├── BackwardCompat/            ← Stage 5+: старые галочки → listener'ы
└── README.md (этот файл)
```

Каждый файл — Gherkin-сценарий, проверяющий конкретный аспект внутреннего компонента через VA-step'ы. Сами step'ы реализованы в `features/Libraries/StreamingReportsTesting/`.

См. полный план — `architecture/testing-strategy.md` в Obsidian-проекте.
