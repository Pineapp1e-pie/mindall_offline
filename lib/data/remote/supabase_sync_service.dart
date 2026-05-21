import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/health_draft.dart';
import '../local/app_database.dart';
import '../local/tables/weather_data.dart';
import 'file_storage_service.dart';

const _kPendingDeletionsKey = 'pending_entry_deletions';
const _kPendingHealthDeletionsKey = 'pending_health_deletions';

/// Данные об ошибке синхронизации для отображения в UI
class SyncIssue {
  final int id;
  final String title;
  final String reason;
  final String details;

  const SyncIssue({
    required this.id,
    required this.title,
    required this.reason,
    required this.details,
  });
}

class SupabaseSyncService extends ChangeNotifier {
  final AppDatabase _db;
  final SupabaseClient _client;
  final FileStorageService _files;

  bool _isSyncing = false;
  int _issueCounter = 0;
  SyncIssue? _pendingIssue;

  SyncIssue? get pendingIssue => _pendingIssue;

  SupabaseSyncService(this._db)
      : _client = Supabase.instance.client,
        _files = FileStorageService();

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('[Sync] user not authenticated');
    return id;
  }

  // ============================================================================
  // Публичные методы синхронизации с поддержкой ошибок для UI
  // ============================================================================

  Future<void> syncAll() async {
    if (_client.auth.currentUser == null) return;
    if (_isSyncing) return;
    _isSyncing = true;

    SyncIssue? firstIssue;

    try {
      firstIssue ??= await _step(
        'deletions',
        flushPendingDeletions().timeout(const Duration(seconds: 10)),
      );
      firstIssue ??= await _step(
        'upload',
        _upload().timeout(const Duration(seconds: 30)),
      );
      firstIssue ??= await _step(
        'download',
        _download().timeout(const Duration(seconds: 120)),
      );
      firstIssue ??= await _step(
        'achievements↓',
        _syncAchievementsFromSupabase().timeout(const Duration(seconds: 30)),
      );
      firstIssue ??= await _step(
        'achievements↑',
        _syncAchievementsToSupabase().timeout(const Duration(seconds: 30)),
      );

      if (firstIssue != null) {
        _publishIssue(firstIssue);
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Очищает показанную ошибку (вызывается из UI после отображения)
  void clearPendingIssue(int id) {
    if (_pendingIssue?.id != id) return;
    _pendingIssue = null;
    notifyListeners();
  }

  /// Метод для очереди удаления записи
  Future<void> queueEntryDeletion(DateTime createdAt) async {
    await _addPendingDeletion(createdAt.toUtc().toIso8601String());
  }

  /// Метод для очереди удаления health-данных
  Future<void> queueHealthDeletion(DateTime day) async {
    await _addPendingHealthDeletion(_formatDay(day));
  }

  /// Удаление записи (моментальное + очередь при ошибке)
  Future<void> deleteEntry(DateTime createdAt) async {
    if (_client.auth.currentUser == null) return;
    final createdAtStr = createdAt.toUtc().toIso8601String();
    print('[Sync] deleteEntry: ставим в очередь удаление записи $createdAtStr');
    await _addPendingDeletion(createdAtStr);
    try {
      print('[Sync] deleteEntry: удаляем связанные данные для $createdAtStr');
      await _client
          .from('context_details')
          .delete()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', createdAtStr);
      await _client
          .from('mood_entry_tags')
          .delete()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', createdAtStr);
      await _client
          .from('weather_data')
          .delete()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', createdAtStr);
      await _client
          .from('mood_entries')
          .delete()
          .eq('user_id', _userId)
          .eq('created_at', createdAtStr);
      await _removePendingDeletion(createdAtStr);
      print('[Sync] deleteEntry: запись и связанные данные удалены');
    } catch (e) {
      print('[Sync] ошибка deleteEntry, добавлено в очередь: $e');
    }
  }

  /// Удаление health-данных за день
  Future<void> deleteHealthForDay(DateTime day) async {
    if (_client.auth.currentUser == null) return;
    final dateStr = _formatDay(day);
    print('[Sync] deleteHealthForDay: ставим в очередь удаление health для $dateStr');
    await _addPendingHealthDeletion(dateStr);
    try {
      print('[Sync] deleteHealthForDay: удаляем health_data для $dateStr в Supabase');
      await _client
          .from('health_data')
          .delete()
          .eq('user_id', _userId)
          .eq('date', dateStr);
      await _removePendingHealthDeletion(dateStr);
      print('[Sync] deleteHealthForDay: health удалён для $dateStr');
    } catch (e) {
      print('[Sync] ошибка deleteHealthForDay, добавлено в очередь: $e');
    }
  }

  /// Удаление тега из записи
  Future<void> deleteTagFromEntry(DateTime entryCreatedAt, String tagName) async {
    if (_client.auth.currentUser == null) return;
    final createdAtStr = entryCreatedAt.toUtc().toIso8601String();
    print('[Sync] deleteTagFromEntry: удаляем тег $tagName у записи $createdAtStr');
    try {
      await _client
          .from('mood_entry_tags')
          .delete()
          .eq('user_id', _userId)
          .eq('mood_entry_created_at', createdAtStr)
          .eq('tag_name', tagName);
      print('[Sync] deleteTagFromEntry: тег удалён');
    } catch (e) {
      print('[Sync] deleteTagFromEntry error: $e');
    }
  }

  // ============================================================================
  // Приватные методы для работы с очередями удаления
  // ============================================================================

  Future<List<String>> _getPendingDeletions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kPendingDeletionsKey) ?? [];
  }

  Future<List<String>> _getPendingHealthDeletions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kPendingHealthDeletionsKey) ?? [];
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

  Future<void> flushPendingDeletions() async {
    final pendingEntries = await _getPendingDeletions();
    for (final iso in List<String>.from(pendingEntries)) {
      try {
        print('[Sync] flush: удаляем mood_entry и связанные данные для $iso');
        await _client
            .from('context_details')
            .delete()
            .eq('user_id', _userId)
            .eq('mood_entry_created_at', iso);
        print('[Sync] flush: context_details удалены для $iso');
        await _client
            .from('mood_entry_tags')
            .delete()
            .eq('user_id', _userId)
            .eq('mood_entry_created_at', iso);
        print('[Sync] flush: mood_entry_tags удалены для $iso');
        await _client
            .from('weather_data')
            .delete()
            .eq('user_id', _userId)
            .eq('mood_entry_created_at', iso);
        print('[Sync] flush: weather_data удалены для $iso');
        await _client
            .from('mood_entries')
            .delete()
            .eq('user_id', _userId)
            .eq('created_at', iso);
        print('[Sync] flush: mood_entries удалена для $iso');
        await _removePendingDeletion(iso);
        print('[Sync] отложенное удаление записи выполнено: $iso');
      } catch (e) {
        print('[Sync] не удалось удалить запись $iso: $e');
      }
    }

    final pendingHealth = await _getPendingHealthDeletions();
    for (final dateStr in List<String>.from(pendingHealth)) {
      try {
        print('[Sync] flush: удаляем health_data для $dateStr');
        await _client
            .from('health_data')
            .delete()
            .eq('user_id', _userId)
            .eq('date', dateStr);
        print('[Sync] flush: health_data удалены для $dateStr');
        await _removePendingHealthDeletion(dateStr);
        print('[Sync] отложенное удаление здоровья выполнено: $dateStr');
      } catch (e) {
        print('[Sync] не удалось удалить health $dateStr: $e');
      }
    }
  }

  // ============================================================================
  // Приватные методы синхронизации с обработкой ошибок для UI
  // ============================================================================

  Future<SyncIssue?> _step(String name, Future<void> work) async {
    try {
      await work;
      return null;
    } catch (e, st) {
      debugPrint('[Sync] ошибка $name: $e\n$st');
      return _buildSyncIssue(e);
    }
  }

  SyncIssue _buildSyncIssue(Object error) {
    final message = error.toString().toLowerCase();
    final reason = switch (error) {
      SocketException() => 'ошибка подключения к серверу',
      TimeoutException() => 'сервер временно не отвечает',
      _ => 'временная ошибка синхронизации',
    };

    return SyncIssue(
      id: ++_issueCounter,
      title: 'Не удалось выполнить синхронизацию',
      reason: reason,
      details: 'Данные сохранены локально и будут повторно отправлены '
          'при восстановлении сети.',
    );
  }

  void _publishIssue(SyncIssue issue) {
    _pendingIssue = issue;
    notifyListeners();
  }

  // ============================================================================
  // Upload методов
  // ============================================================================

  Future<void> _upload() async {
    print('[Sync] upload: начало');
    final entries = await _db.select(_db.moodEntries).get();
    if (entries.isNotEmpty) {
      print('[Sync] upload: отправка ${entries.length} mood_entries');
      await _client.from('mood_entries').upsert(
        entries
            .map(
              (e) => {
            'user_id': _userId,
            'created_at': e.createdAt.toUtc().toIso8601String(),
            'mood_id': e.moodId,
          },
        )
            .toList(),
      );
      print('[Sync] upload: mood_entries успешно отправлены');
    }

    for (final entry in entries) {
      final createdAtStr = entry.createdAt.toUtc().toIso8601String();
      print('[Sync] upload: обрабатываем запись $createdAtStr');

      // --- Context ---
      try {
        final ctx = await (_db.select(_db.contextDetails)
          ..where((c) => c.moodEntryId.equals(entry.id)))
            .getSingleOrNull();
        if (ctx == null) {
          print('[Sync] upload: контекст для $createdAtStr отсутствует локально, удаляем в Supabase');
          await _client
              .from('context_details')
              .delete()
              .eq('user_id', _userId)
              .eq('mood_entry_created_at', createdAtStr);
          print('[Sync] upload: контекст удалён для $createdAtStr');
        } else {
          final ts = entry.createdAt.millisecondsSinceEpoch;
          print('[Sync] ctx для entry $ts: voice=${ctx.voicePath}, photo=${ctx.photoPath}');

          String? remoteVoicePath = ctx.voicePath;
          var includeVoicePath = true;
          if (ctx.voicePath != null && _files.isLocalPath(ctx.voicePath!)) {
            final storagePath = '$_userId/$ts.aac';
            print('[Sync] upload: загружаем голосовое $storagePath');
            remoteVoicePath = await _files.uploadVoice(ctx.voicePath!, storagePath);
            includeVoicePath = remoteVoicePath != null;
            print('[Sync] upload: результат загрузки голоса: $remoteVoicePath');
          }

          String? remotePhotoPath = ctx.photoPath;
          var includePhotoPath = true;
          if (ctx.photoPath != null) {
            final paths = _parsePhotoPaths(ctx.photoPath!);
            final uploaded = <String>[];
            var allOk = true;
            for (var i = 0; i < paths.length; i++) {
              final path = paths[i];
              if (_files.isLocalPath(path)) {
                final storagePath = '$_userId/${ts}_$i.jpg';
                print('[Sync] upload: загружаем фото $storagePath');
                final uploadedPath = await _files.uploadPhoto(path, storagePath);
                if (uploadedPath == null) {
                  allOk = false;
                  includePhotoPath = false;
                  break;
                }
                uploaded.add(uploadedPath);
              } else {
                uploaded.add(path);
              }
            }
            if (allOk) {
              remotePhotoPath = jsonEncode(uploaded);
            }
          }

          final ctxData = <String, dynamic>{
            'user_id': _userId,
            'mood_entry_created_at': createdAtStr,
            'note': ctx.note,
            if (includeVoicePath) 'voice_path': remoteVoicePath,
            if (includePhotoPath) 'photo_path': remotePhotoPath,
          };
          print('[Sync] upload: upsert контекста для $createdAtStr');
          await _client.from('context_details').upsert(ctxData);
          print('[Sync] upload: контекст успешно отправлен');
        }
      } catch (e, st) {
        print('[Sync] upload: ошибка при обработке контекста для $createdAtStr: $e\n$st');
      }

      // --- Tags ---
      try {
        final tagQuery = _db.select(_db.contextTags).join([
          innerJoin(
            _db.moodEntryTags,
            _db.moodEntryTags.tagId.equalsExp(_db.contextTags.id),
          ),
        ])..where(_db.moodEntryTags.moodEntryId.equals(entry.id));
        final tagRows = await tagQuery.get();
        print('[Sync] upload: удаляем старые теги для $createdAtStr');
        await _client
            .from('mood_entry_tags')
            .delete()
            .eq('user_id', _userId)
            .eq('mood_entry_created_at', createdAtStr);
        if (tagRows.isNotEmpty) {
          final tagsToUpsert = tagRows
              .map((row) {
            final tag = row.readTable(_db.contextTags);
            return {
              'user_id': _userId,
              'mood_entry_created_at': createdAtStr,
              'tag_name': tag.name,
            };
          })
              .toList();
          print('[Sync] upload: отправляем ${tagsToUpsert.length} тегов для $createdAtStr');
          await _client.from('mood_entry_tags').upsert(tagsToUpsert);
          print('[Sync] upload: теги успешно отправлены');
        } else {
          print('[Sync] upload: тегов для $createdAtStr нет, только удалили старые');
        }
      } catch (e, st) {
        print('[Sync] upload: ошибка при обработке тегов для $createdAtStr: $e\n$st');
      }

      // --- Weather ---
      try {
        final weather = await (_db.select(_db.weatherData)
          ..where((w) => w.moodEntryId.equals(entry.id)))
            .getSingleOrNull();
        if (weather == null) {
          print('[Sync] upload: погода для $createdAtStr отсутствует локально, удаляем в Supabase');
          await _client
              .from('weather_data')
              .delete()
              .eq('user_id', _userId)
              .eq('mood_entry_created_at', createdAtStr);
          print('[Sync] upload: погода удалена для $createdAtStr');
        } else {
          print('[Sync] upload: upsert погоды для $createdAtStr');
          await _client.from('weather_data').upsert({
            'user_id': _userId,
            'mood_entry_created_at': createdAtStr,
            'source': weather.source,
            'temperature_category': weather.temperatureCategory.index,
            'raw_temperature': weather.rawTemperature,
            'precipitation': weather.precipitation?.index,
            'cloudiness': weather.cloudiness?.index,
          });
          print('[Sync] upload: погода успешно отправлена');
        }
      } catch (e, st) {
        print('[Sync] upload: ошибка при обработке погоды для $createdAtStr: $e\n$st');
      }
    }

    // --- Health ---
    final healthRows = await _db.select(_db.healthData).get();
    if (healthRows.isNotEmpty) {
      print('[Sync] upload: отправка ${healthRows.length} health_data');
      await _client.from('health_data').upsert(
        healthRows
            .map(
              (h) => {
            'user_id': _userId,
            'date': _formatDay(h.date),
            'sleep_minutes': h.sleepMinutes,
            'steps_amount': h.stepsAmount,
            'cycle_phase': h.cyclePhase?.name,
            'source': h.source,
          },
        )
            .toList(),
      );
      print('[Sync] upload: health_data успешно отправлены');
    }
  }

  // ============================================================================
  // Download методов
  // ============================================================================

  String _formatDay(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';

  List<String> _parsePhotoPaths(String raw) {
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [raw];
    }
  }

  Future<String?> _downloadVoicePath(String? remotePath) async {
    if (remotePath != null && _files.isStoragePath(remotePath)) {
      print('[Sync] download: загружаем голосовое $remotePath');
      return await _files.downloadVoice(remotePath) ?? remotePath;
    }
    return remotePath;
  }

  Future<String?> _downloadPhotoPath(String? remotePath) async {
    if (remotePath == null) return null;
    final paths = _parsePhotoPaths(remotePath);
    final downloaded = <String>[];
    for (final path in paths) {
      if (_files.isStoragePath(path)) {
        print('[Sync] download: загружаем фото $path');
        downloaded.add(await _files.downloadPhoto(path) ?? path);
      } else {
        downloaded.add(path);
      }
    }
    return jsonEncode(downloaded);
  }

  Future<void> _download() async {
    print('=== DOWNLOAD START ===');

    final remoteEntries =
    await _client.from('mood_entries').select().eq('user_id', _userId);
    print('[Sync] download: получено ${remoteEntries.length} mood_entries из Supabase');
    final allContext =
    await _client.from('context_details').select().eq('user_id', _userId);
    print('[Sync] download: получено ${allContext.length} context_details');
    final allTags =
    await _client.from('mood_entry_tags').select().eq('user_id', _userId);
    print('[Sync] download: получено ${allTags.length} mood_entry_tags');
    final allWeather =
    await _client.from('weather_data').select().eq('user_id', _userId);
    print('[Sync] download: получено ${allWeather.length} weather_data');
    final remoteHealth =
    await _client.from('health_data').select().eq('user_id', _userId);
    print('[Sync] download: получено ${remoteHealth.length} health_data');

    final pendingDeletions = await _getPendingDeletions();
    final pendingHealthDeletions = (await _getPendingHealthDeletions()).toSet();

    for (final row in remoteEntries) {
      final remoteCreatedAtStr = row['created_at'] as String;
      final createdAtUtc = remoteCreatedAtStr.split('.').first;

      if (pendingDeletions.any((iso) => iso.startsWith(createdAtUtc))) {
        print('[Sync] download: пропускаем удалённую запись $remoteCreatedAtStr (в очереди удаления)');
        continue;
      }

      final createdAt = DateTime.parse(remoteCreatedAtStr).toLocal();
      final existingEntry = await (_db.select(_db.moodEntries)
        ..where(
              (e) => e.createdAt.equals(createdAt) & e.userId.equals(_userId),
        ))
          .getSingleOrNull();
      if (existingEntry != null) {
        print('[Sync] download: запись $remoteCreatedAtStr уже существует локально, пропускаем');
        continue;
      }

      print('[Sync] download: создаём новую локальную запись для $remoteCreatedAtStr');
      final localEntryId = await _db.into(_db.moodEntries).insert(
        MoodEntriesCompanion.insert(
          userId: _userId,
          moodId: row['mood_id'] as int,
          createdAt: Value(createdAt),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final ctxRows = allContext
          .where((c) => c['mood_entry_created_at'] == remoteCreatedAtStr)
          .toList();
      if (ctxRows.isNotEmpty) {
        final ctx = ctxRows.first;
        print('[Sync] download: добавляем контекст для $remoteCreatedAtStr');
        await _db.into(_db.contextDetails).insert(
          ContextDetailsCompanion.insert(
            moodEntryId: localEntryId,
            note: Value(ctx['note'] as String?),
            voicePath: Value(
              await _downloadVoicePath(ctx['voice_path'] as String?),
            ),
            photoPath: Value(
              await _downloadPhotoPath(ctx['photo_path'] as String?),
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      final tagRows = allTags
          .where((t) => t['mood_entry_created_at'] == remoteCreatedAtStr)
          .toList();
      for (final tagRow in tagRows) {
        final tagName = tagRow['tag_name'] as String;
        final localTag = await (_db.select(_db.contextTags)
          ..where((t) => t.name.equals(tagName)))
            .getSingleOrNull();
        if (localTag != null) {
          await _db.into(_db.moodEntryTags).insert(
            MoodEntryTagsCompanion.insert(
              moodEntryId: localEntryId,
              tagId: localTag.id,
              updatedAt: Value(DateTime.now()),
            ),
          );
          print('[Sync] download: добавлен тег $tagName для $remoteCreatedAtStr');
        } else {
          print('[Sync] download: тег $tagName не найден локально, пропускаем');
        }
      }

      final weatherRows = allWeather
          .where((w) => w['mood_entry_created_at'] == remoteCreatedAtStr)
          .toList();
      if (weatherRows.isNotEmpty) {
        final w = weatherRows.first;
        print('[Sync] download: добавляем погоду для $remoteCreatedAtStr');
        await _db.into(_db.weatherData).insert(
          WeatherDataCompanion.insert(
            moodEntryId: localEntryId,
            source: w['source'] as String? ?? 'manual',
            temperatureCategory: TemperatureCategory.values[w['temperature_category'] as int],
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
            rawTemperature: Value((w['raw_temperature'] as num?)?.toDouble()),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }

    for (final row in remoteHealth) {
      final dateStr = row['date'] as String;
      if (pendingHealthDeletions.contains(dateStr)) {
        print('[Sync] download: health для $dateStr в очереди удаления, пропускаем');
        continue;
      }

      final date = DateTime.parse(dateStr);
      final existingHealth = await (_db.select(_db.healthData)
        ..where((h) => h.date.equals(date)))
          .getSingleOrNull();
      if (existingHealth != null) {
        print('[Sync] download: health для $dateStr уже есть локально, пропускаем');
        continue;
      }

      print('[Sync] download: создаём health для $dateStr');
      await _db.into(_db.healthData).insert(
        HealthDataCompanion.insert(
          date: date,
          sleepMinutes: Value(row['sleep_minutes'] as int?),
          stepsAmount: Value(row['steps_amount'] as int?),
          cyclePhase: Value(
            row['cycle_phase'] != null
                ? CyclePhase.values.firstWhere(
                  (phase) => phase.name == row['cycle_phase'],
              orElse: () => CyclePhase.follicular,
            )
                : null,
          ),
          source: Value(row['source'] as String?),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    print('=== DOWNLOAD DONE ===');
  }

  // ============================================================================
  // Синхронизация достижений
  // ============================================================================

  Future<void> _syncAchievementsFromSupabase() async {
    print('[Sync] achievements↓: начало');
    final remote =
    await _client.from('user_achievements').select().eq('user_id', _userId);
    print('[Sync] achievements↓: получено ${remote.length} достижений');

    for (final row in remote) {
      final achievementId = row['achievement_id'] as String;
      final achievedAtStr = row['achieved_at'] as String?;
      final achievedAt =
      achievedAtStr != null ? DateTime.parse(achievedAtStr) : DateTime.now();

      final localRows = await (_db.select(_db.userAchievements)
        ..where(
              (a) => a.userId.equals(_userId) & a.achievementId.equals(achievementId),
        ))
          .get();

      if (localRows.isEmpty || localRows.first.isAchieved) continue;

      print('[Sync] achievements↓: обновляем достижение $achievementId');
      await (_db.update(_db.userAchievements)
        ..where(
              (a) => a.userId.equals(_userId) & a.achievementId.equals(achievementId),
        ))
          .write(
        UserAchievementsCompanion(
          isAchieved: const Value(true),
          achievedAt: Value(achievedAt),
          synced: const Value(true),
        ),
      );
    }
  }

  Future<void> _syncAchievementsToSupabase() async {
    print('[Sync] achievements↑: начало');
    final unsynced = await (_db.select(_db.userAchievements)
      ..where(
            (a) => a.userId.equals(_userId) & a.isAchieved.equals(true) & a.synced.equals(false),
      ))
        .get();
    print('[Sync] achievements↑: найдено ${unsynced.length} unsynced');
    if (unsynced.isEmpty) return;

    print('[Sync] achievements↑: отправка ${unsynced.length} несинхронизированных достижений');
    await _client.from('user_achievements').upsert(
      unsynced
          .map(
            (a) => {
          'user_id': _userId,
          'achievement_id': a.achievementId,
          'achieved_at': a.achievedAt?.toUtc().toIso8601String(),
        },
      )
          .toList(),
    );
    print('[Sync] achievements↑: ${unsynced.length} достижения отправлены');

    for (final achievement in unsynced) {
      await (_db.update(_db.userAchievements)
        ..where(
              (row) => row.userId.equals(_userId) & row.achievementId.equals(achievement.achievementId),
        ))
          .write(const UserAchievementsCompanion(synced: Value(true)));
    }
  }
}