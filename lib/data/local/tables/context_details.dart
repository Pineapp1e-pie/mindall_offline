import 'package:drift/drift.dart';

import 'mood_entries.dart';

class ContextDetails extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get moodEntryId =>
      integer().references(MoodEntries, #id)();

  TextColumn get note => text().nullable()();
  TextColumn get voicePath => text().nullable()();
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
