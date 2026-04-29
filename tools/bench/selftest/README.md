# selftest profile — TBD

Профиль `selftest` — подвыборка из существующих self-tests VA с минимальной зависимостью от сторонних компонент:
- `features/Core/Variables/` (10)
- `features/Core/RegExp/` (1)
- `features/Core/ExecuteCode/` (1)
- `features/Core/ExpectedSomething/` (3)
- `features/Core/FixtureJSONLoad/` (1)
- `features/Core/Translate/` (9)
- `features/Core/KnownSteps/` (6)
- `features/Core/ErrorDetails/` (3)
- `features/Core/ErrorJson/` (?)

**Большинство всё же требует тест-клиент** (`Я запускаю сценарий открытия TestClient`). Поэтому для smoke-bench запускаются repro2498 и heavy — они работают без тест-клиента.

selftest_10/20/50.json появятся в Stage 1 как часть baseline-замера. Тогда же будет принято решение — какие конкретно фича-файлы выбрать (зависит от того, какие требуют тест-клиент, а какие не требуют).
