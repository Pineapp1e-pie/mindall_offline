import 'package:drift/drift.dart';
import 'package:mindall/data/local/tables/health_data.dart';

import '../../../domain/models/mood_entry_with_mood.dart';
import '../app_database.dart';
import 'local_repository.dart';

class LocalRepositoryImpl implements LocalRepository {
  final AppDatabase db;

  LocalRepositoryImpl(this.db);

  // ---------- Mood entries ----------

  @override
  Future<int> insertMoodEntry(MoodEntriesCompanion entry) {
    return db.into(db.moodEntries).insert(entry);
  }
  //
  // @override
  // Future<List<MoodEntry>> getMoodEntriesForDay(DateTime day) {
  //   final start = DateTime(day.year, day.month, day.day);
  //   final end = start.add(const Duration(days: 1));
  //
  //   return (db.select(db.moodEntries)
  //     ..where((m) =>
  //     m.createdAt.isBiggerOrEqualValue(start) &
  //     m.createdAt.isSmallerThanValue(end))
  //     ..orderBy([
  //           (m) => OrderingTerm(expression: m.createdAt),
  //     ]))
  //       .get();
  // }
  @override
  Future<List<MoodEntryWithMood>> getMoodEntriesForDay(
      DateTime day,
      ) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final query = db.select(db.moodEntries).join([
      innerJoin(
        db.moods,
        db.moods.id.equalsExp(db.moodEntries.moodId),
      ),
    ])
      ..where(db.moodEntries.createdAt.isBetweenValues(start, end));

    final rows = await query.get();

    return rows.map((row) {
      return MoodEntryWithMood(
        entry: row.readTable(db.moodEntries),
        mood: row.readTable(db.moods),
      );
    }).toList();
  }


  @override
  Future<List<MoodEntry>> getMoodEntriesForPeriod(
      DateTime from,
      DateTime to,
      ) {
    return (db.select(db.moodEntries)
      ..where((m) =>
      m.createdAt.isBiggerOrEqualValue(from) &
      m.createdAt.isSmallerOrEqualValue(to))
      ..orderBy([
            (m) => OrderingTerm(expression: m.createdAt),
      ]))
        .get();
  }

  // ---------- Daily stats ----------

  @override
  Future<DailyMoodStat?> getDailyMoodStat(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);

    return (db.select(db.dailyMoodStats)
      ..where((d) => d.date.equals(date)))
        .getSingleOrNull();
  }

  @override
  Future<List<DailyMoodStat>> getDailyMoodStats(
      DateTime from,
      DateTime to,
      ) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    return (db.select(db.dailyMoodStats)
      ..where((d) =>
      d.date.isBiggerOrEqualValue(start) &
      d.date.isSmallerOrEqualValue(end))
      ..orderBy([
            (d) => OrderingTerm(expression: d.date),
      ]))
        .get();
  }


  @override
  Future<void> upsertDailyMoodStat(
      DailyMoodStatsCompanion stat,
      ) async {
    await db.into(db.dailyMoodStats).insertOnConflictUpdate(stat);
  }



  @override
  Future<HealthDataData?> getHealthDataForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);

    return (db.select(db.healthData)
      ..where((h) => h.date.equals(date)))
        .getSingleOrNull();
  }



}
