import 'package:drift/drift.dart';

import 'context_tags.dart';
import 'mood_entries.dart';


class MoodEntryTags extends Table {
  IntColumn get moodEntryId =>
      integer().references(MoodEntries, #id)();

  IntColumn get tagId =>
      integer().references(ContextTags, #id)();

  @override
  Set<Column> get primaryKey => {moodEntryId, tagId};

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
