# language: ru
# encoding: utf-8

@bench @smoke @heavy @N10 @StreamingReports

Функционал: Heavy bench — комбинация аккумуляторов (10 итераций)

  Имитирует «тяжёлый» сценарий: цикл с накоплением переменных + объёмные
  значения. Бьёт по ПеременныеДляСохраненияВШаг + ВсеПеременныеШага.

  Контекст:
    Дано Я запоминаю значение выражения '0' в переменную "I"
    И    Я запоминаю значение выражения '"["' в переменную "Buffer"

  Сценарий: Цикл с тяжёлыми значениями
    Когда пока выражение встроенного языка '$I$ < 10' истинно я выполняю
      И Я запоминаю значение выражения '$I$ + 1' в переменную "I"
      И Я запоминаю значение выражения '$Buffer$ + Строка($I$) + ": lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua,"' в переменную "Buffer"
      И Я запоминаю значение выражения '"ItemValue_" + Строка($I$) + "_payload_lorem_ipsum_dolor_sit_amet_consectetur_adipiscing"' в переменную "$I$"
