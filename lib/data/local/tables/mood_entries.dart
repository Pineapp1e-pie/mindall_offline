import 'package:drift/drift.dart';

import '../static/moods.dart';

class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userId => text()();

  IntColumn get moodId =>
      integer().references(Moods, #id)();


  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
