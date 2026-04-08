import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Отвечает только за загрузку и скачивание файлов (фото и голосовых)
/// в Supabase Storage. Не знает ничего про синхронизацию БД.
///
/// Соглашение о путях:
///   локальный путь  — начинается с '/'  (абсолютный путь на устройстве)
///   путь в Storage  — НЕ начинается с '/' (например: userId/voice_123.aac)
class FileStorageService {
  static const _photoBucket = 'photos';
  static const _voiceBucket = 'voices';

  final SupabaseClient _client;

  FileStorageService() : _client = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // Вспомогательные методы
  // ─────────────────────────────────────────────

  /// Локальный путь — начинается с '/'
  bool isLocalPath(String? path) => path != null && path.startsWith('/');

  /// Путь в Storage — не начинается с '/'
  bool isStoragePath(String? path) =>
      path != null && path.isNotEmpty && !path.startsWith('/');

  // ─────────────────────────────────────────────
  // UPLOAD
  // ─────────────────────────────────────────────

  /// Загружает фото из [localPath] в Storage по пути [storagePath].
  /// Возвращает [storagePath] при успехе, null при ошибке.
  /// upsert: true — безопасно вызывать повторно, файл просто перезапишется.
  Future<String?> uploadPhoto(String localPath, String storagePath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        print('[Storage] uploadPhoto: файл не найден локально: $localPath');
        return null;
      }
      print('[Storage] uploadPhoto: загружаем → $storagePath');
      await _client.storage.from(_photoBucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      print('[Storage] uploadPhoto: успешно');
      return storagePath;
    } catch (e) {
      print('[Storage] uploadPhoto: ОШИБКА $e');
      return null;
    }
  }

  Future<String?> uploadVoice(String localPath, String storagePath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        print('[Storage] uploadVoice: файл не найден локально: $localPath');
        return null;
      }
      print('[Storage] uploadVoice: загружаем → $storagePath');
      await _client.storage.from(_voiceBucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      print('[Storage] uploadVoice: успешно');
      return storagePath;
    } catch (e) {
      print('[Storage] uploadVoice: ОШИБКА $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // DOWNLOAD
  // ─────────────────────────────────────────────

  /// Скачивает фото из Storage по пути [storagePath] и сохраняет локально.
  /// Если файл уже есть на устройстве — не скачивает повторно.
  /// Возвращает локальный путь при успехе, null при ошибке.
  Future<String?> downloadPhoto(String storagePath) async {
    return _downloadFile(_photoBucket, storagePath);
  }

  /// Скачивает голосовое из Storage по пути [storagePath] и сохраняет локально.
  Future<String?> downloadVoice(String storagePath) async {
    return _downloadFile(_voiceBucket, storagePath);
  }

  Future<String?> _downloadFile(String bucket, String storagePath) async {
    try {
      final fileName = storagePath.split('/').last;
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/$fileName';

      if (File(localPath).existsSync()) {
        print('[Storage] downloadFile: уже есть локально $localPath');
        return localPath;
      }

      print('[Storage] downloadFile: скачиваем $bucket/$storagePath');
      final bytes = await _client.storage.from(bucket).download(storagePath);
      await File(localPath).writeAsBytes(bytes);
      print('[Storage] downloadFile: успешно → $localPath');
      return localPath;
    } catch (e) {
      print('[Storage] downloadFile: ОШИБКА $e');
      return null;
    }
  }
}
