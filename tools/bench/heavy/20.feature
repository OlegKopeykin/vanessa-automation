# language: ru
# encoding: utf-8

@bench @heavy @N20 @StreamingReports

Функционал: Heavy bench (20 итераций)

  Контекст:
    Дано Я запоминаю значение выражения '0' в переменную "I"
    И    Я запоминаю значение выражения '"["' в переменную "Buffer"

  Сценарий: Цикл с тяжёлыми значениями
    Когда пока выражение встроенного языка '$I$ < 20' истинно я выполняю
      И Я запоминаю значение выражения '$I$ + 1' в переменную "I"
      И Я запоминаю значение выражения '$Buffer$ + Строка($I$) + ": lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua,"' в переменную "Buffer"
      И Я запоминаю значение выражения '"ItemValue_" + Строка($I$) + "_payload_lorem_ipsum_dolor_sit_amet_consectetur_adipiscing"' в переменную "$I$"
