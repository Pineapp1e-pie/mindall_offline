import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mindall/data/local/static/moods.dart';
import 'package:mindall/data/local/tables/daily_mood_stats.dart';
import 'package:mindall/data/local/tables/user_achievements.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/health_draft.dart';
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
    UserAchievements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(userAchievements);
          }
          if (from < 3) {
            // Removed 'notified' column — drop and recreate preserving data.
            await customStatement(
              'CREATE TABLE user_achievements_new ('
              '"achievement_id" TEXT NOT NULL, '
              '"user_id" TEXT NOT NULL, '
              '"is_achieved" INTEGER NOT NULL DEFAULT 0 '
              'CHECK ("is_achieved" IN (0, 1)), '
              '"achieved_at" INTEGER, '
              '"synced" INTEGER NOT NULL DEFAULT 0 '
              'CHECK ("synced" IN (0, 1)), '
              'PRIMARY KEY ("user_id", "achievement_id"))',
            );
            await customStatement(
              'INSERT INTO user_achievements_new '
              'SELECT achievement_id, user_id, is_achieved, achieved_at, synced '
              'FROM user_achievements',
            );
            await customStatement('DROP TABLE user_achievements');
            await customStatement(
              'ALTER TABLE user_achievements_new RENAME TO user_achievements',
            );
          }
        },
      );

  Future<void> clearUserData() async {
    await delete(moodEntryTags).go();
    await delete(contextDetails).go();
    await delete(weatherData).go();
    await delete(healthData).go();
    await delete(dailyMoodStats).go();
    await delete(moodEntries).go();
    await delete(userAchievements).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mindal.db'));
    return NativeDatabase(file);
  });
}
