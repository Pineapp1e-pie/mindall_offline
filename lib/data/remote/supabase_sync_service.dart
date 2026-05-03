
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/app_database.dart';
import '../../domain/models/health_draft.dart';
import '../local/tables/weather_data.dart';
import 'file_storage_service.dart';

const _kPendingDeletionsKey = 'pending_entry_deletions';
const _kPendingHealthDeletionsKey = 'pending_health_deletions';

class SupabaseSyncService {
  final AppDatabase _db;
  final SupabaseClient _client;
  final FileStorageService _files;

  bool _isSyncing = false;

  SupabaseSyncService(this._db)
      : _client = Supabase.instance.client,
        _files = FileStorageService();

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('[Sync] user not authenticated');
    return id;
  }

  /// Полная синхронизация: сначала загружаем локальное в облако,
  /// потом скачиваем из облака то, чего нет локально.
  Future<void> syncAll() async {
    if (_client.auth.currentUser == null) return;
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _step('deletions', flushPendingDeletions().timeout(const Duration(seconds: 10)));
      await _step('upload', _upload().timeout(const Duration(seconds: 30)));
      await _step('download', _download().timeout(const Duration(seconds: 30)));
      await _step('achievements↓', _syncAchievementsFromSupabase().timeout(const Duration(seconds: 10)));
      await _step('achievements↑', _syncAchievementsToSupabase().timeout(const Duration(seconds: 10)));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _step(String name, Future<void> work) async {
    try {
      await work;
    } catch (e, st) {
      print('[Sync] ошибка $name: $e\n$st');
    }
  }

  // ─────────────────────────────────────────────
  // PENDING DELETIONS — офлайн-очередь удалений
  // ─────────────────────────────────────────────

  Future<List<String>> _getPendingDeletions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kPendingDeletionsKey) ?? [];
  }

  Future<void> _addPendingDeletion(String createdAtIso) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingDeletionsKey) ?? [];
    if (!list.contains(createdAtIso)) {
      list.add(createdAtIso);
      await prefs.setStringList(_kPendingDeletionsKey, list);
    }
  }

  Future<void> _removePendingDeletion(String createdAtIso) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingDeletionsKey) ?? [];
    list.remove(createdAtIso);
    await prefs.setStringList(_kPendingDeletionsKey, list);
  }

  /// Только добавляет запись в очередь удалений — без сетевых вызовов.
  /// Используется при офлайн-удалении.
  Future<void> queueEntryDeletion(DateTime createdAt) async {
    await _addPendingDeletion(createdAt.toUtc().toIso8601String());
  }

  /// Только добавляет health-запись в очередь удалений — без сетевых вызовов.
  /// Используется при офлайн-удалении.
  Future<void> queueHealthDeletion(DateTime day) async {
    final dateStr =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    await _addPendingHealthDeletion(dateStr);
  }

  Future<void> _addPendingHealthDeletion(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingHealthDeletionsKey) ?? [];
    if (!list.contains(dateStr)) {
      list.add(dateStr);
      await prefs.setStringList(_kPendingHealthDeletionsKey, list);
    }
  }

  Future<void> _removePendingHealthDeletion(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingHealthDeletionsKey) ?? [];
    list.remove(dateStr);
    await prefs.setStringList(_kPendingHealthDeletionsKey, list);
  }

  /// Отправляет в Supabase все накопленные удаления, которые не дошли офлайн.
  Future<void> flushPendingDeletions() async {
    final prefs = await SharedPreferences.getInstance();

    // Записи настроения
    final pendingEntries = prefs.getStringList(_kPendingDeletionsKey) ?? [];
    for (final iso in List<String>.from(pendingEntries)) {
      try {
        await _client.from('context_details').delete()
            .eq('user_id', _userId).eq('mood_entry_created_at', iso);
        await _client.from('mood_entry_tags').delete()
            .eq('user_id', _userId).eq('mood_entry_created_at', iso);
        await _client.from('weather_data').delete()
            .eq('user_id', _userId).eq('mood_entry_created_at', iso);
        await _client.from('mood_entries').delete()
            .eq('user_id', _userId).eq('created_at', iso);
        await _removePendingDeletion(iso);
        print('[Sync] отложенное удаление записи выполнено: $iso');
      } catch (e) {
        print('[Sync] не удалось удалить запись $iso: $e');
      }
    }

    // Данные здоровья
    final pendingHealth = prefs.getStringList(_kPendingHealthDeletionsKey) ?? [];
    for (final dateStr in List<String>.from(pendingHealth)) {
      try {
        await _client.from('health_data').delete()
            .eq('user_id', _userId).eq('date', dateStr);
        await _removePendingHealthDeletion(dateStr);
        print('[Sync] отложенное удаление здоровья выполнено: $dateStr');
      } catch (e) {
        print('[Sync] не удалось удалить health $dateStr: $e');
      }
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
        final ts = entry.createdAt.millisecondsSinceEpoch;

        print('[Sync] ctx для entry $ts: voice=${ctx.voicePath}, photo=${ctx.photoPath}');

        // Правило: в Supabase БД пишем ТОЛЬКО Storage-пути.
        // Если upload не удался — поле не включаем в upsert совсем,
        // чтобы не затереть Storage-путь из предыдущей успешной синхронизации.

        String? uploadedVoicePath; // Storage-путь, только если upload успешен
        if (_files.isLocalPath(ctx.voicePath)) {
          print('[Sync] голосовое локальное, загружаем: ${ctx.voicePath}');
          final storagePath = '$_userId/$ts.aac';
          uploadedVoicePath = await _files.uploadVoice(ctx.voicePath!, storagePath);
          print('[Sync] голосовое: ${uploadedVoicePath != null ? "успешно" : "ОШИБКА, пропускаем"}');
        }

        String? uploadedPhotoPath; // JSON Storage-путей, только если все успешны
        if (ctx.photoPath != null) {
          final paths = _parsePhotoPaths(ctx.photoPath!);
          print('[Sync] фото: ${paths.length} файлов');
          final uploaded = <String>[];
          bool allOk = true;
          for (int i = 0; i < paths.length; i++) {
            if (_files.isLocalPath(paths[i])) {
              final storagePath = '$_userId/${ts}_$i.jpg';
              final result = await _files.uploadPhoto(paths[i], storagePath);
              print('[Sync] фото[$i]: ${result != null ? "успешно" : "ОШИБКА"}');
              if (result != null) {
                uploaded.add(result);
              } else {
                allOk = false;
                break; // один не загрузился — не пишем в Supabase
              }
            } else {
              uploaded.add(paths[i]); // уже Storage-путь
            }
          }
          if (allOk) uploadedPhotoPath = jsonEncode(uploaded);
        }

        // Формируем upsert только с теми полями, которые точно являются Storage-путями
        final ctxData = <String, dynamic>{
          'user_id': _userId,
          'mood_entry_created_at': createdAtStr,
          'note': ctx.note,
          if (uploadedVoicePath != null) 'voice_path': uploadedVoicePath,
          if (uploadedPhotoPath != null) 'photo_path': uploadedPhotoPath,
        };
        await _client.from('context_details').upsert(ctxData);
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
  // HELPERS
  // ─────────────────────────────────────────────

  /// Парсит photo_path: поддерживает JSON-массив и одиночный путь (legacy).
  List<String> _parsePhotoPaths(String raw) {
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [raw];
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

    final pendingDeletions = await _getPendingDeletions();

    for (final row in remoteEntries) {
      final remoteCreatedAtStr = row['created_at'] as String;
      final createdAtUtc = remoteCreatedAtStr.split('.').first; // обрезаем микросекунды для сравнения

      // Пропускаем записи, ожидающие удаления офлайн — иначе они вернутся
      if (pendingDeletions.any((iso) => iso.startsWith(createdAtUtc))) continue;

      final createdAt = DateTime.parse(remoteCreatedAtStr).toLocal();

      // Проверяем — есть ли уже локально для этого пользователя
      final exists = await (_db.select(_db.moodEntries)
            ..where((e) => e.createdAt.equals(createdAt) & e.userId.equals(_userId)))
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

        // Голосовое: если путь в Storage (не локальный) — скачиваем файл,
        // в локальную БД пишем локальный путь на этом устройстве.
        String? voicePath = ctx['voice_path'] as String?;
        if (_files.isStoragePath(voicePath)) {
          voicePath = await _files.downloadVoice(voicePath!) ?? voicePath;
        }

        // Фото: скачиваем каждый файл из Storage, заменяем на локальные пути.
        String? photoPath = ctx['photo_path'] as String?;
        if (photoPath != null) {
          final paths = _parsePhotoPaths(photoPath);
          final downloaded = <String>[];
          for (final path in paths) {
            if (_files.isStoragePath(path)) {
              final local = await _files.downloadPhoto(path);
              downloaded.add(local ?? path);
            } else {
              downloaded.add(path);
            }
          }
          photoPath = jsonEncode(downloaded);
        }

        await _db.into(_db.contextDetails).insert(
          ContextDetailsCompanion.insert(
            moodEntryId: localEntryId,
            note: Value(ctx['note'] as String?),
            voicePath: Value(voicePath),
            photoPath: Value(photoPath),
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
      await _db.into(_db.healthData).insertOnConflictUpdate(
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
      );
    }
  }

  // ─────────────────────────────────────────────
  // ACHIEVEMENTS — двусторонняя синхронизация
  // ─────────────────────────────────────────────

  /// Шаг А: скачать ачивки с Supabase и обновить локальные.
  Future<void> _syncAchievementsFromSupabase() async {
    final remote = await _client
        .from('user_achievements')
        .select()
        .eq('user_id', _userId);

    for (final row in remote) {
      final achievementId = row['achievement_id'] as String;
      final achievedAtStr = row['achieved_at'] as String?;
      final achievedAt =
          achievedAtStr != null ? DateTime.parse(achievedAtStr) : DateTime.now();

      final localRows = await (_db.select(_db.userAchievements)
            ..where((a) =>
                a.userId.equals(_userId) &
                a.achievementId.equals(achievementId)))
          .get();

      if (localRows.isEmpty || localRows.first.isAchieved) continue;

      await (_db.update(_db.userAchievements)
            ..where((a) =>
                a.userId.equals(_userId) &
                a.achievementId.equals(achievementId)))
          .write(UserAchievementsCompanion(
        isAchieved: const Value(true),
        achievedAt: Value(achievedAt),
        synced: const Value(true),
      ));
    }
  }

  /// Шаг Б: залить в Supabase локальные выполненные ачивки.
  Future<void> _syncAchievementsToSupabase() async {
    final unsynced = await (_db.select(_db.userAchievements)
          ..where((a) =>
              a.userId.equals(_userId) &
              a.isAchieved.equals(true) &
              a.synced.equals(false)))
        .get();
    if (unsynced.isEmpty) return;

    await _client.from('user_achievements').upsert(
      unsynced.map((a) => {
        'user_id': _userId,
        'achievement_id': a.achievementId,
        'achieved_at': a.achievedAt?.toUtc().toIso8601String(),
      }).toList(),
    );

    for (final a in unsynced) {
      await (_db.update(_db.userAchievements)
            ..where((r) =>
                r.userId.equals(_userId) &
                r.achievementId.equals(a.achievementId)))
          .write(const UserAchievementsCompanion(synced: Value(true)));
    }
  }

  /// Удаляет данные здоровья из Supabase по дате.
  /// Если нет сети — добавляет в очередь отложенных удалений.
  Future<void> deleteHealthForDay(DateTime day) async {
    if (_client.auth.currentUser == null) return;
    final dateStr =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    await _addPendingHealthDeletion(dateStr);
    try {
      await _client.from('health_data').delete()
          .eq('user_id', _userId).eq('date', dateStr);
      await _removePendingHealthDeletion(dateStr);
    } catch (e) {
      print('[Sync] ошибка deleteHealthForDay, добавлено в очередь: $e');
    }
  }

  /// Удаляет тег записи из Supabase.
  Future<void> deleteTagFromEntry(DateTime entryCreatedAt, String tagName) async {
    if (_client.auth.currentUser == null) return;
    try {
      await _client.from('mood_entry_tags').delete()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', entryCreatedAt.toUtc().toIso8601String())
          .eq('tag_name', tagName);
    } catch (e) {
      print('[Sync] deleteTagFromEntry error: $e');
    }
  }

  /// Удаляет запись из Supabase по createdAt.
  /// Если нет сети — добавляет в очередь отложенных удалений.
  Future<void> deleteEntry(DateTime createdAt) async {
    if (_client.auth.currentUser == null) return;
    final createdAtStr = createdAt.toUtc().toIso8601String();
    // Сразу регистрируем как pending — защита от повторной загрузки при _download
    await _addPendingDeletion(createdAtStr);
    try {
      await _client.from('context_details').delete()
          .eq('user_id', _userId).eq('mood_entry_created_at', createdAtStr);
      await _client.from('mood_entry_tags').delete()
          .eq('user_id', _userId).eq('mood_entry_created_at', createdAtStr);
      await _client.from('weather_data').delete()
          .eq('user_id', _userId).eq('mood_entry_created_at', createdAtStr);
      await _client.from('mood_entries').delete()
          .eq('user_id', _userId).eq('created_at', createdAtStr);
      // Успешно удалили — убираем из очереди
      await _removePendingDeletion(createdAtStr);
    } catch (e) {
      print('[Sync] ошибка deleteEntry, добавлено в очередь: $e');
      // Запись остаётся в pending — будет удалена при следующем syncAll()
    }
  }
}
