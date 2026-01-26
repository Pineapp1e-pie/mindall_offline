import 'package:drift/drift.dart';

class DailyMoodStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();

  RealColumn get avgX => real()();
  RealColumn get avgY => real()();

  RealColumn get moodValue => real()();
  // значение для графиков

  TextColumn get dayType => text()();
// stable_psitive_calmo
// positive
// negative
// contrast
}

// 1. Пользователь добавил запись настроения
// 2. Сохранили MoodEntry
// 3. Взяли все MoodEntry за этот день
// 4. Посчитали avgX, avgY
// 5. Определили квадранты
// 6. Определили тип дня
// 7. Обновили / сохранили DailyMoodStats
