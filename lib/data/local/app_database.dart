import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mindall/data/local/static/moods.dart';
import 'package:mindall/data/local/tables/daily_mood_stats.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/mood_entries.dart';
import 'tables/context_tags.dart';
import 'tables/mood_entry_tags.dart';
import 'tables/context_details.dart';
import 'tables/weather_data.dart';
import 'tables/health_data.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    MoodEntries,
    ContextTags,
    MoodEntryTags,
    ContextDetails,
    WeatherData,
    HealthData,
    DailyMoodStats,
    Moods,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mindal.db'));
    return NativeDatabase(file);
  });
}
