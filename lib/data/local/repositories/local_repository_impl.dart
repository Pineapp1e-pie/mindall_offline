import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:mindall/data/local/tables/health_data.dart';

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
  Stream<List<MoodEntryWithMood>> watchMoodEntriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final query = db.select(db.moodEntries).join([
      innerJoin(
        db.moods,
        db.moods.id.equalsExp(db.moodEntries.moodId),
      ),
    ])
      ..where(db.moodEntries.createdAt.isBetweenValues(start, end));

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
          userId: "1",
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
      if (draft.health != null) {
        await db.into(db.healthData).insert(
          HealthDataCompanion.insert(
            date: draft.health!.date,
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
      ..where(db.moodEntries.createdAt.isBetweenValues(from, to));

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
      ..where(db.moodEntries.createdAt.isBetweenValues(from, to))
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
      // 1. Update mood
      await (db.update(db.moodEntries)..where((e) => e.id.equals(entryId)))
          .write(MoodEntriesCompanion(moodId: Value(draft.moodId)));

      // 2. Update context details
      final existing = await (db.select(db.contextDetails)
            ..where((c) => c.moodEntryId.equals(entryId)))
          .getSingleOrNull();
      final contextCompanion = ContextDetailsCompanion(
        note: Value(draft.note.isEmpty ? null : draft.note),
        voicePath:
            Value(draft.recordPath.isEmpty ? null : draft.recordPath),
        photoPath: Value(
          draft.imagePaths.isNotEmpty
              ? jsonEncode(draft.imagePaths)
              : null,
        ),
      );
      if (existing != null) {
        await (db.update(db.contextDetails)
              ..where((c) => c.moodEntryId.equals(entryId)))
            .write(contextCompanion);
      } else {
        await db.into(db.contextDetails).insert(
          ContextDetailsCompanion.insert(
            moodEntryId: entryId,
            note: contextCompanion.note,
            voicePath: contextCompanion.voicePath,
            photoPath: contextCompanion.photoPath,
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
      if (draft.health != null) {
        await db.into(db.healthData).insert(
          HealthDataCompanion.insert(
            date: draft.health!.date,
            sleepMinutes: Value(draft.health!.sleepMinutes),
            stepsAmount: Value(draft.health!.stepsAmount),
            cyclePhase: Value(draft.health!.cyclePhase),
            source: Value(draft.health!.source),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
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
}
