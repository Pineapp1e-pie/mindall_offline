import 'package:drift/drift.dart';

import 'mood_entries.dart';


class WeatherData extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get moodEntryId =>
      integer().references(MoodEntries, #id)();

  RealColumn get temperature => real().nullable()();
  TextColumn get condition => text().nullable()();
}
