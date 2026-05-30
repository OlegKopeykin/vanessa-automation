# scenarios/ — дескрипторы сценариев прогона

Сценарий описывает **что гонять**: теги отбора, теги исключения, и опционально фиксированный набор ячеек (combos).

## Поля

| Поле | Тип | Описание |
|---|---|---|
| `selectTags` | массив | Whitelist тегов → `СписокТеговОтбор` (пустой = все тесты) |
| `baseExclude` | массив | Базовые теги исключения (платформа и флейвор добавят свои сверху) |
| `combos` | массив объектов | Явный список `{platform, flavor}` ячеек для прогона |
| `matrix` | объект | Декларативная матрица `{platforms:[...], flavors:[...]}` (альтернатива combos) |
| `_overrides` | объект | Поля VBParams, которые перекрывают defaults/platform/flavor (например `КоличествоПопытокВыполненияСценария`) |

## Добавить сценарий

1. Создать `scenarios/<name>.json`.
2. Заполнить `selectTags` и `baseExclude`.
3. Если нужен фиксированный набор ячеек — добавить `combos`.
4. Проверить: `oscript tools/checks/check.os --scenario <name> --platform 8.3.27 --flavor uf --dry-run`.

## Примеры

### Простой (только теги)

```json
{
   "_description": "Тесты производительности.",
   "selectTags": ["Performance"],
   "baseExclude": ["Ignore"]
}
```

### С combos

```json
{
   "_description": "CI-прогон на CI-матрице.",
   "selectTags": [],
   "baseExclude": ["IgnoreOnCIMainBuild", "Ignore"],
   "combos": [
      { "platform": "8.3.27", "flavor": "uf" },
      { "platform": "8.3.27", "flavor": "web" },
      { "platform": "8.5.1",  "flavor": "uf" }
   ]
}
```

### С _overrides

```json
{
   "_description": "FastCheck без retry.",
   "selectTags": [],
   "baseExclude": ["IgnoreOnCIMainBuild", "IgnoreOnFastCheck", "Ignore", "Video"],
   "_overrides": {
      "КоличествоПопытокВыполненияСценария": "1",
      "ВыводитьВЛогВыполнениеШагов": "Истина"
   }
}
```

## Как работает baseExclude

`СписокТеговИсключение` в итоговом VBParams = `baseExclude ∪ platformExcludeTags ∪ flavorExcludeTags`.

Сценарий задаёт только свои "бизнес-теги" исключения (`IgnoreOnCIMainBuild`, `Ignore`, специфичные для сценария). Платформа добавит `IgnoreOn<ver>`, флейвор — `IgnoreOnUFBuilds` / `IgnoreOnWeb` и т.п.
