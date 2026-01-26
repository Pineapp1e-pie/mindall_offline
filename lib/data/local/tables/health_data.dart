import 'package:drift/drift.dart';

import 'mood_entries.dart';

enum ActivityLevel {
  low,
  medium,
  high,
}


class HealthData extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get date => dateTime()();

  RealColumn get sleepHours => real().nullable()();

  TextColumn get activityLevel =>
      textEnum<ActivityLevel>().nullable()();

  IntColumn get cycleDay => integer().nullable()();
}
