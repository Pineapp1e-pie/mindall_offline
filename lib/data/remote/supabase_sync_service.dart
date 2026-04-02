import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/app_database.dart';
import '../local/tables/context_details.dart';
import '../local/tables/health_data.dart';
import '../local/tables/mood_entries.dart';
import '../../domain/models/health_draft.dart';
import '../local/tables/weather_data.dart';

class SupabaseSyncService {
  final AppDatabase _db;
  final SupabaseClient _client;

  SupabaseSyncService(this._db) : _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// Полная синхронизация: сначала загружаем локальное в облако,
  /// потом скачиваем из облака то, чего нет локально.
  Future<void> syncAll() async {
    if (_client.auth.currentUser == null) return;
    try {
      await _upload();
      await _download();
    } catch (_) {
      // Тихо падаем — повторим при следующем запуске или появлении сети
    }
  }

  // ─────────────────────────────────────────────
  // UPLOAD — локальное → Supabase
  // ─────────────────────────────────────────────

  Future<void> _upload() async {
    final entries = await _db.select(_db.moodEntries).get();
    if (entries.isEmpty) return;

    // 1. mood_entries (батч)
    await _client.from('mood_entries').upsert(
      entries.map((e) => {
        'user_id': _userId,
        'created_at': e.createdAt.toUtc().toIso8601String(),
        'mood_id': e.moodId,
      }).toList(),
    );

    for (final entry in entries) {
      final createdAtStr = entry.createdAt.toUtc().toIso8601String();

      // 2. context_details
      final ctx = await (_db.select(_db.contextDetails)
            ..where((c) => c.moodEntryId.equals(entry.id)))
          .getSingleOrNull();
      if (ctx != null) {
        await _client.from('context_details').upsert({
          'user_id': _userId,
          'mood_entry_created_at': createdAtStr,
          'note': ctx.note,
          'voice_path': ctx.voicePath,
          'photo_path': ctx.photoPath,
        });
      }

      // 3. mood_entry_tags (через join)
      final tagQuery = _db.select(_db.contextTags).join([
        innerJoin(
          _db.moodEntryTags,
          _db.moodEntryTags.tagId.equalsExp(_db.contextTags.id),
        ),
      ])..where(_db.moodEntryTags.moodEntryId.equals(entry.id));
      final tagRows = await tagQuery.get();
      if (tagRows.isNotEmpty) {
        await _client.from('mood_entry_tags').upsert(
          tagRows.map((row) {
            final tag = row.readTable(_db.contextTags);
            return {
              'user_id': _userId,
              'mood_entry_created_at': createdAtStr,
              'tag_name': tag.name,
            };
          }).toList(),
        );
      }

      // 4. weather_data
      final weather = await (_db.select(_db.weatherData)
            ..where((w) => w.moodEntryId.equals(entry.id)))
          .getSingleOrNull();
      if (weather != null) {
        await _client.from('weather_data').upsert({
          'user_id': _userId,
          'mood_entry_created_at': createdAtStr,
          'source': weather.source,
          'temperature_category': weather.temperatureCategory.index,
          'raw_temperature': weather.rawTemperature,
          'precipitation': weather.precipitation?.index,
          'cloudiness': weather.cloudiness?.index,
        });
      }
    }

    // 5. health_data (батч)
    final healthRows = await _db.select(_db.healthData).get();
    if (healthRows.isNotEmpty) {
      await _client.from('health_data').upsert(
        healthRows.map((h) => {
          'user_id': _userId,
          'date': '${h.date.year.toString().padLeft(4, '0')}-'
              '${h.date.month.toString().padLeft(2, '0')}-'
              '${h.date.day.toString().padLeft(2, '0')}',
          'sleep_minutes': h.sleepMinutes,
          'steps_amount': h.stepsAmount,
          'cycle_phase': h.cyclePhase?.name,
          'source': h.source,
        }).toList(),
      );
    }
  }

  // ─────────────────────────────────────────────
  // DOWNLOAD — Supabase → локальное
  // ─────────────────────────────────────────────

  Future<void> _download() async {
    // 1. mood_entries
    final remoteEntries = await _client
        .from('mood_entries')
        .select()
        .eq('user_id', _userId);

    for (final row in remoteEntries) {
      final createdAt = DateTime.parse(row['created_at'] as String).toLocal();

      // Проверяем — есть ли уже локально
      final exists = await (_db.select(_db.moodEntries)
            ..where((e) => e.createdAt.equals(createdAt)))
          .getSingleOrNull();
      if (exists != null) continue;

      // Вставляем mood_entry
      final localEntryId = await _db.into(_db.moodEntries).insert(
        MoodEntriesCompanion.insert(
          userId: _userId,
          moodId: row['mood_id'] as int,
          createdAt: Value(createdAt),
        ),
      );

      final remoteCreatedAt = row['created_at'] as String;

      // context_details
      final ctxRows = await _client
          .from('context_details')
          .select()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', remoteCreatedAt);
      if (ctxRows.isNotEmpty) {
        final ctx = ctxRows.first;
        await _db.into(_db.contextDetails).insert(
          ContextDetailsCompanion.insert(
            moodEntryId: localEntryId,
            note: Value(ctx['note'] as String?),
            voicePath: Value(ctx['voice_path'] as String?),
            photoPath: Value(ctx['photo_path'] as String?),
          ),
        );
      }

      // mood_entry_tags — ищем локальный тег по имени
      final tagRows = await _client
          .from('mood_entry_tags')
          .select()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', remoteCreatedAt);
      for (final tagRow in tagRows) {
        final tagName = tagRow['tag_name'] as String;
        final localTag = await (_db.select(_db.contextTags)
              ..where((t) => t.name.equals(tagName)))
            .getSingleOrNull();
        if (localTag != null) {
          await _db.into(_db.moodEntryTags).insertOnConflictUpdate(
            MoodEntryTagsCompanion.insert(
              moodEntryId: localEntryId,
              tagId: localTag.id,
            ),
          );
        }
      }

      // weather_data
      final weatherRows = await _client
          .from('weather_data')
          .select()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', remoteCreatedAt);
      if (weatherRows.isNotEmpty) {
        final w = weatherRows.first;
        await _db.into(_db.weatherData).insert(
          WeatherDataCompanion.insert(
            moodEntryId: localEntryId,
            source: w['source'] as String? ?? 'manual',
            temperatureCategory: TemperatureCategory
                .values[w['temperature_category'] as int],
            precipitation: Value(
              w['precipitation'] != null
                  ? PrecipitationType.values[w['precipitation'] as int]
                  : null,
            ),
            cloudiness: Value(
              w['cloudiness'] != null
                  ? Cloudiness.values[w['cloudiness'] as int]
                  : null,
            ),
            rawTemperature: Value(
              (w['raw_temperature'] as num?)?.toDouble(),
            ),
          ),
        );
      }
    }

    // 2. health_data
    final remoteHealth = await _client
        .from('health_data')
        .select()
        .eq('user_id', _userId);
    for (final h in remoteHealth) {
      final date = DateTime.parse(h['date'] as String);
      await _db.into(_db.healthData).insert(
        HealthDataCompanion.insert(
          date: date,
          sleepMinutes: Value(h['sleep_minutes'] as int?),
          stepsAmount: Value(h['steps_amount'] as int?),
          cyclePhase: Value(
            h['cycle_phase'] != null
                ? CyclePhase.values.firstWhere(
                    (p) => p.name == h['cycle_phase'],
                    orElse: () => CyclePhase.follicular,
                  )
                : null,
          ),
          source: Value(h['source'] as String?),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
}
