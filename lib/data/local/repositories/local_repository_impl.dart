import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:mindall/data/local/tables/health_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/achievement.dart';
import '../../../domain/models/mood_entry_with_mood.dart';
import '../../../domain/models/weather_draft.dart';
import '../../../domain/models/health_draft.dart';
import '../app_database.dart';
import '../tables/context_details.dart';
import '../tables/context_tags.dart';
import '../tables/weather_data.dart';
import 'local_repository.dart';
import '../../../domain/models/mood_entry_draft.dart';

class LocalRepositoryImpl implements LocalRepository {
  final AppDatabase db;

  LocalRepositoryImpl(this.db);

  @override
  Future<void> clearUserData() => db.clearUserData();

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _hasHealthPayload(HealthDraft? health) =>
      health != null &&
      (health.sleepMinutes != null ||
          health.stepsAmount != null ||
          health.cyclePhase != null);

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
      ..where(db.moodEntries.createdAt.isBetweenValues(start, end) &
          db.moodEntries.userId.equals(_userId));

    final rows = await query.get();

    return rows.map((row) {
      return MoodEntryWithMood(
        entry: row.readTable(db.moodEntries),
        mood: row.readTable(db.moods),
      );
    }).toList();
  }


  @override
  Stream<List<MoodEntryWithMood>> watchMoodEntriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final query = db.select(db.moodEntries).join([
      innerJoin(
        db.moods,
        db.moods.id.equalsExp(db.moodEntries.moodId),
      ),
    ])
      ..where(db.moodEntries.createdAt.isBetweenValues(start, end) &
          db.moodEntries.userId.equals(_userId));

    return query.watch().map((rows) => rows.map((row) {
          return MoodEntryWithMood(
            entry: row.readTable(db.moodEntries),
            mood: row.readTable(db.moods),
          );
        }).toList());
  }

  @override
  Future<List<MoodEntry>> getMoodEntriesForPeriod(
      DateTime from,
      DateTime to,
      ) {
    return (db.select(db.moodEntries)
      ..where((m) =>
      m.createdAt.isBiggerOrEqualValue(from) &
      m.createdAt.isSmallerOrEqualValue(to) &
      m.userId.equals(_userId))
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
  @override
  Future<void> deleteDailyMoodStatForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return (db.delete(db.dailyMoodStats)
          ..where((d) => d.date.equals(date)))
        .go();
  }

  Future<void> upsertDailyMoodStat(
      DailyMoodStatsCompanion stat,
      ) async {
    final rows = await (db.select(db.dailyMoodStats)
          ..where((d) => d.date.equals(stat.date.value)))
        .get();
    if (rows.isNotEmpty) {
      // Удаляем все дубли и оставляем одну актуальную строку
      await (db.delete(db.dailyMoodStats)
            ..where((d) => d.date.equals(stat.date.value)))
          .go();
    }
    await db.into(db.dailyMoodStats).insert(stat);
  }



  @override
  Future<HealthDataData?> getHealthDataForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);

    return (db.select(db.healthData)
      ..where((h) => h.date.equals(date)))
        .getSingleOrNull();
  }


  @override
  Future<void> insertHealthData(HealthDataCompanion data) async {
    await db.into(db.healthData).insertOnConflictUpdate(data);
  }

  @override
  Future<void> insertContextDetails(ContextDetailsCompanion data) {
    return db.into(db.contextDetails).insert(data);
  }

  @override
  Future<void> saveFullEntry(MoodEntryDraft draft) async {

    await db.transaction(() async {

      /// 1. mood
      final entryId = await db.into(db.moodEntries).insert(
        MoodEntriesCompanion.insert(
          userId: _userId,
          moodId: draft.moodId,
        ),
      );

      /// 2. context + notes
      await db.into(db.contextDetails).insert(
        ContextDetailsCompanion.insert(
          moodEntryId: entryId,
          note: Value(draft.note.isEmpty ? null : draft.note),
          voicePath: Value(draft.recordPath.isEmpty ? null : draft.recordPath),
          photoPath: Value(
            draft.imagePaths.isNotEmpty
                ? jsonEncode(draft.imagePaths)
                : null,
          ),
        ),
      );

      /// 3. теги (место, действие, общество)
      final allTagIds = [
        ...draft.placeTagIds,
        ...draft.activityTagIds,
        ...draft.socialTagIds,
      ];
      for (final tagId in allTagIds) {
        await db.into(db.moodEntryTags).insert(
          MoodEntryTagsCompanion.insert(
            moodEntryId: entryId,
            tagId: tagId,
          ),
        );
      }

      /// 4. health
      if (_hasHealthPayload(draft.health)) {
        await db.into(db.healthData).insert(
          HealthDataCompanion.insert(
            date: _normalizeDay(draft.health!.date),
            sleepMinutes: Value(draft.health!.sleepMinutes),
            stepsAmount: Value(draft.health!.stepsAmount),
            cyclePhase: Value(draft.health!.cyclePhase),
            source: Value(draft.health!.source),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      /// 4. weather
      if (draft.weather != null) {
        await db.into(db.weatherData).insert(
          WeatherDataCompanion.insert(
            moodEntryId: entryId,
            source: draft.weather!.source,
            temperatureCategory: draft.weather!.temperature!,
            precipitation: Value(draft.weather!.precipitation),
            cloudiness: Value(draft.weather!.cloudiness),
            rawTemperature: Value(draft.weather!.rawTemperature),
          ),
        );
      }

    });
  }

  @override
  Future<ContextDetail?> getContextDetailsForEntry(int entryId) async {
    return await (db.select(db.contextDetails)
      ..where((t) => t.moodEntryId.equals(entryId)))
        .getSingleOrNull();
  }

  @override
  Future<List<ContextTag>> getTagsForEntry(int entryId) async {
    final query = db.select(db.contextTags).join([
      innerJoin(
        db.moodEntryTags,
        db.moodEntryTags.tagId.equalsExp(db.contextTags.id),
      ),
    ])
      ..where(db.moodEntryTags.moodEntryId.equals(entryId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(db.contextTags)).toList();
  }

  @override
  Future<WeatherDataData?> getWeatherForEntry(int entryId) async {
    return await (db.select(db.weatherData)
      ..where((w) => w.moodEntryId.equals(entryId)))
        .getSingleOrNull();
  }

  @override
  Future<List<MoodWeatherRecord>> getMoodWeatherPairs(
      DateTime from, DateTime to) async {
    final query = db.select(db.moodEntries).join([
      innerJoin(db.moods, db.moods.id.equalsExp(db.moodEntries.moodId)),
      innerJoin(
          db.weatherData,
          db.weatherData.moodEntryId.equalsExp(db.moodEntries.id)),
    ])
      ..where(db.moodEntries.createdAt.isBetweenValues(from, to) &
          db.moodEntries.userId.equals(_userId));

    final rows = await query.get();
    return rows.map((row) {
      final mood = row.readTable(db.moods);
      final weather = row.readTable(db.weatherData);
      return MoodWeatherRecord(
        moodX: mood.x,
        moodName: mood.name,
        temperatureCategory: weather.temperatureCategory,
        rawTemperature: weather.rawTemperature,
      );
    }).toList();
  }

  @override
  Future<List<HealthDataData>> getHealthDataForPeriod(
      DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    return (db.select(db.healthData)
          ..where((h) =>
              h.date.isBiggerOrEqualValue(start) &
              h.date.isSmallerOrEqualValue(end))
          ..orderBy([(h) => OrderingTerm(expression: h.date)]))
        .get();
  }

  @override
  Future<List<MoodEntryWithMood>> getMoodEntriesWithMoodForPeriod(
      DateTime from, DateTime to) async {
    final query = db.select(db.moodEntries).join([
      innerJoin(db.moods, db.moods.id.equalsExp(db.moodEntries.moodId)),
    ])
      ..where(db.moodEntries.createdAt.isBetweenValues(from, to) &
          db.moodEntries.userId.equals(_userId))
      ..orderBy([OrderingTerm(expression: db.moodEntries.createdAt)]);

    final rows = await query.get();
    return rows.map((row) => MoodEntryWithMood(
          entry: row.readTable(db.moodEntries),
          mood: row.readTable(db.moods),
        )).toList();
  }

  @override
  Future<void> deleteMoodEntry(int entryId) async {
    await db.transaction(() async {
      await (db.delete(db.weatherData)
            ..where((w) => w.moodEntryId.equals(entryId)))
          .go();
      await (db.delete(db.moodEntryTags)
            ..where((t) => t.moodEntryId.equals(entryId)))
          .go();
      await (db.delete(db.contextDetails)
            ..where((c) => c.moodEntryId.equals(entryId)))
          .go();
      await (db.delete(db.moodEntries)
            ..where((e) => e.id.equals(entryId)))
          .go();
    });
  }

  @override
  Future<void> deleteHealthDataForDay(DateTime day) async {
    final date = DateTime(day.year, day.month, day.day);
    await (db.delete(db.healthData)..where((h) => h.date.equals(date))).go();
  }

  @override
  Future<MoodEntryDraft> getMoodEntryAsDraft(int entryId) async {
    final entry = await (db.select(db.moodEntries)
          ..where((e) => e.id.equals(entryId)))
        .getSingle();

    final contextDetails = await (db.select(db.contextDetails)
          ..where((c) => c.moodEntryId.equals(entryId)))
        .getSingleOrNull();

    final tagQuery = db.select(db.contextTags).join([
      innerJoin(
        db.moodEntryTags,
        db.moodEntryTags.tagId.equalsExp(db.contextTags.id),
      ),
    ])
      ..where(db.moodEntryTags.moodEntryId.equals(entryId));
    final tagRows = await tagQuery.get();
    final tags = tagRows.map((r) => r.readTable(db.contextTags)).toList();

    final weather = await (db.select(db.weatherData)
          ..where((w) => w.moodEntryId.equals(entryId)))
        .getSingleOrNull();

    final d = entry.createdAt;
    final health = await (db.select(db.healthData)
          ..where((h) => h.date.equals(DateTime(d.year, d.month, d.day))))
        .getSingleOrNull();

    List<String> imagePaths = [];
    if (contextDetails?.photoPath != null) {
      try {
        final decoded = jsonDecode(contextDetails!.photoPath!);
        if (decoded is List) imagePaths = decoded.cast<String>();
      } catch (_) {
        imagePaths = [contextDetails!.photoPath!];
      }
    }

    return MoodEntryDraft(
      editingEntryId: entryId,
      entryDate: entry.createdAt,
      moodId: entry.moodId,
      placeTagIds: tags
          .where((t) => t.type == ContextTagType.place)
          .map((t) => t.id)
          .toList(),
      activityTagIds: tags
          .where((t) => t.type == ContextTagType.activity)
          .map((t) => t.id)
          .toList(),
      socialTagIds: tags
          .where((t) => t.type == ContextTagType.social)
          .map((t) => t.id)
          .toList(),
      note: contextDetails?.note ?? '',
      imagePaths: imagePaths,
      recordPath: contextDetails?.voicePath ?? '',
      weather: weather != null
          ? WeatherDraft(
              source: weather.source,
              temperature: weather.temperatureCategory,
              precipitation: weather.precipitation,
              cloudiness: weather.cloudiness,
            )
          : null,
      health: health != null
          ? HealthDraft(
              date: health.date,
              sleepMinutes: health.sleepMinutes,
              stepsAmount: health.stepsAmount,
              cyclePhase: health.cyclePhase,
              source: health.source ?? 'manual',
            )
          : null,
    );
  }

  @override
  Future<void> updateFullEntry(int entryId, MoodEntryDraft draft) async {
    await db.transaction(() async {
      final entry = await (db.select(db.moodEntries)
            ..where((e) => e.id.equals(entryId)))
          .getSingle();
      final healthDate = _normalizeDay(entry.createdAt);

      // 1. Update mood
      await (db.update(db.moodEntries)..where((e) => e.id.equals(entryId)))
          .write(MoodEntriesCompanion(moodId: Value(draft.moodId)));

      // 2. Update context details
      final existing = await (db.select(db.contextDetails)
            ..where((c) => c.moodEntryId.equals(entryId)))
          .getSingleOrNull();
      final note = draft.note.trim().isEmpty ? null : draft.note;
      final voicePath = draft.recordPath.isEmpty ? null : draft.recordPath;
      final photoPath =
          draft.imagePaths.isNotEmpty ? jsonEncode(draft.imagePaths) : null;
      final hasContextPayload =
          note != null || voicePath != null || photoPath != null;
      if (!hasContextPayload) {
        if (existing != null) {
          await (db.delete(db.contextDetails)
                ..where((c) => c.moodEntryId.equals(entryId)))
              .go();
        }
      } else if (existing != null) {
        await (db.update(db.contextDetails)
              ..where((c) => c.moodEntryId.equals(entryId)))
            .write(
          ContextDetailsCompanion(
            note: Value(note),
            voicePath: Value(voicePath),
            photoPath: Value(photoPath),
          ),
        );
      } else {
        await db.into(db.contextDetails).insert(
          ContextDetailsCompanion.insert(
            moodEntryId: entryId,
            note: Value(note),
            voicePath: Value(voicePath),
            photoPath: Value(photoPath),
          ),
        );
      }

      // 3. Tags — delete and re-insert
      await (db.delete(db.moodEntryTags)
            ..where((t) => t.moodEntryId.equals(entryId)))
          .go();
      for (final tagId in [
        ...draft.placeTagIds,
        ...draft.activityTagIds,
        ...draft.socialTagIds,
      ]) {
        await db.into(db.moodEntryTags).insert(
          MoodEntryTagsCompanion.insert(
              moodEntryId: entryId, tagId: tagId),
        );
      }

      // 4. Weather — delete and re-insert
      await (db.delete(db.weatherData)
            ..where((w) => w.moodEntryId.equals(entryId)))
          .go();
      if (draft.weather != null) {
        await db.into(db.weatherData).insert(
          WeatherDataCompanion.insert(
            moodEntryId: entryId,
            source: draft.weather!.source,
            temperatureCategory: draft.weather!.temperature!,
            precipitation: Value(draft.weather!.precipitation),
            cloudiness: Value(draft.weather!.cloudiness),
            rawTemperature: Value(draft.weather!.rawTemperature),
          ),
        );
      }

      // 5. Health — upsert
      if (_hasHealthPayload(draft.health)) {
        await db.into(db.healthData).insert(
          HealthDataCompanion.insert(
            date: healthDate,
            sleepMinutes: Value(draft.health!.sleepMinutes),
            stepsAmount: Value(draft.health!.stepsAmount),
            cyclePhase: Value(draft.health!.cyclePhase),
            source: Value(draft.health!.source),
          ),
          mode: InsertMode.insertOrReplace,
        );
      } else {
        await (db.delete(db.healthData)
              ..where((h) => h.date.equals(healthDate)))
            .go();
      }
    });
  }

  // ── Achievements ──────────────────────────────────────────────────────────

  @override
  Future<void> initAchievementsForUser(String userId) async {
    for (final a in kAchievements) {
      await db.into(db.userAchievements).insert(
        UserAchievementsCompanion.insert(
          achievementId: a.id,
          userId: userId,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  @override
  Future<int> countUserAchievements(String userId) async {
    final countExp = db.userAchievements.achievementId.count();
    final query = db.selectOnly(db.userAchievements)
      ..addColumns([countExp])
      ..where(db.userAchievements.userId.equals(userId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<List<UserAchievement>> getUnachievedAchievements(String userId) =>
      (db.select(db.userAchievements)
            ..where((a) =>
                a.userId.equals(userId) & a.isAchieved.equals(false)))
          .get();

  @override
  Future<List<UserAchievement>> getAllAchievements(String userId) =>
      (db.select(db.userAchievements)
            ..where((a) => a.userId.equals(userId)))
          .get();

  @override
  Future<void> markAchievementAchieved(
      String userId, String achievementId, DateTime achievedAt) async {
    await (db.update(db.userAchievements)
          ..where((a) =>
              a.userId.equals(userId) &
              a.achievementId.equals(achievementId)))
        .write(UserAchievementsCompanion(
      isAchieved: const Value(true),
      achievedAt: Value(achievedAt),
      synced: const Value(false),
    ));
  }

  @override
  Future<List<UserAchievement>> getUnsyncedAchievements(String userId) =>
      (db.select(db.userAchievements)
            ..where((a) =>
                a.userId.equals(userId) &
                a.isAchieved.equals(true) &
                a.synced.equals(false)))
          .get();

  @override
  Future<void> markAchievementsSynced(
      String userId, List<String> achievementIds) async {
    for (final id in achievementIds) {
      await (db.update(db.userAchievements)
            ..where((a) =>
                a.userId.equals(userId) & a.achievementId.equals(id)))
          .write(const UserAchievementsCompanion(synced: Value(true)));
    }
  }

  // ── Stats for achievement checks ──────────────────────────────────────────

  @override
  Future<int> countMoodEntries(String userId) async {
    final countExp = db.moodEntries.id.count();
    final query = db.selectOnly(db.moodEntries)
      ..addColumns([countExp])
      ..where(db.moodEntries.userId.equals(userId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<List<DateTime>> getUniqueMoodEntryDates(String userId) async {
    // created_at is stored as Unix seconds (Drift's currentDateAndTime = strftime('%s','now'))
    final rows = await db.customSelect(
      "SELECT DISTINCT date(created_at, 'unixepoch', 'localtime') AS d "
      'FROM mood_entries WHERE user_id = ? ORDER BY d DESC',
      variables: [Variable.withString(userId)],
      readsFrom: {db.moodEntries},
    ).get();
    return rows.map((r) => DateTime.parse(r.read<String>('d'))).toList();
  }

  @override
  Future<int> getDistinctMoodCategoryCount(String userId) async {
    final rows = await db.customSelect(
      'SELECT COUNT(DISTINCT m.category) AS cnt '
      'FROM mood_entries me '
      'JOIN moods m ON m.id = me.mood_id '
      'WHERE me.user_id = ?',
      variables: [Variable.withString(userId)],
      readsFrom: {db.moodEntries, db.moods},
    ).get();
    return rows.first.read<int>('cnt');
  }

  @override
  Future<DateTime?> getFirstMoodEntryDate(String userId) async {
    final query = db.select(db.moodEntries)
      ..where((e) => e.userId.equals(userId))
      ..orderBy([(e) => OrderingTerm(expression: e.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.createdAt;
  }

  @override
  Future<void> updateNote(int entryId, String? note) async {
    final existing = await (db.select(db.contextDetails)
          ..where((c) => c.moodEntryId.equals(entryId)))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.contextDetails)
            ..where((c) => c.moodEntryId.equals(entryId)))
          .write(ContextDetailsCompanion(note: Value(note)));
    } else {
      await db.into(db.contextDetails).insert(
        ContextDetailsCompanion.insert(
          moodEntryId: entryId,
          note: Value(note),
        ),
      );
    }
  }

  @override
  Future<void> removeTagFromEntry(int entryId, int tagId) async {
    await (db.delete(db.moodEntryTags)
          ..where((t) =>
              t.moodEntryId.equals(entryId) & t.tagId.equals(tagId)))
        .go();
  }
}
