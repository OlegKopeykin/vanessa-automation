#!/usr/bin/env oscript
// tools/checks/view-allure.os — universal entrypoint для просмотра Allure-отчёта.
// Эквивалент старого "3 ViewAllureReport.cmd".
//
// СТАТУС: STUB. Реализация по образцу tools/3 ViewAllureReport.cmd.
//
// =============================================================================
// КОНТРАКТ
// =============================================================================
//
// Использование:
//   oscript tools/checks/view-allure.os
//
// Без аргументов. Открывает текущий Allure-отчёт в браузере.
//
// Требует:
//   - allure CLI в PATH (https://github.com/allure-framework/allure2)
//   - Java (для allure)
//   - Существующий tools/ServiceBases/allurereport/ (заполняется после check)
//
// =============================================================================
// АЛГОРИТМ
// =============================================================================
//
// 1. Определение ОС
// 2. Запуск платформенной обёртки: platform/<ОС>/view-allure.{cmd|sh}
// 3. Команды внутри:
//    a) cd tools/ServiceBases/allurereport
//    b) allure generate --clean ./*
//    c) allure open ./allure-report
//
// =============================================================================

Сообщить("[STUB] tools/checks/view-allure.os ещё не реализован.");
Сообщить("Используйте старый: tools\\3 ViewAllureReport.cmd");
ЗавершитьРаботуСистемы(Ложь, Истина, 1);
