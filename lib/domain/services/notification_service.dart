//
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../services/user_profile_service.dart';
//
//
//
// class NotificationService {
//   static final NotificationService _instance = NotificationService._();
//   factory NotificationService() => _instance;
//   NotificationService._();
//
//   final _plugin = FlutterLocalNotificationsPlugin();
//
//   static const _channelId = 'mood_reminder';
//   static const _channelName = 'Напоминания о настроении';
//
//   Future<void> init() async {
//     // Локальные уведомления для отображения когда приложение открыто
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     await _plugin.initialize(
//       const InitializationSettings(android: androidSettings),
//     );
//
//     // Создаём канал с высоким приоритетом
//     const channel = AndroidNotificationChannel(
//       _channelId,
//       _channelName,
//       description: 'Ежедневные напоминания записать настроение',
//       importance: Importance.high,
//     );
//     await _plugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//
//
//   /// Сохраняет FCM-токен + настройки уведомлений в Supabase.
//   /// Сервер (Edge Function) читает это и отправляет push в нужное время.
//   Future<void> saveNotificationSettings({
//     required bool enabled,
//     required int hour,
//     required int minute,
//   }) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//
//     final token = await FirebaseMessaging.instance.getToken();
//     if (token == null) return;
//
//     final utcOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
//
//     await Supabase.instance.client.from('push_tokens').upsert(
//       {
//         'user_id': userId,
//         'fcm_token': token,
//         'notif_enabled': enabled,
//         'notif_hour': hour,
//         'notif_minute': minute,
//         'utc_offset_minutes': utcOffsetMinutes,
//         'updated_at': DateTime.now().toUtc().toIso8601String(),
//       },
//       onConflict: 'user_id',
//     );
//   }
//
//   /// Загружает настройки уведомлений из Supabase и сохраняет в SharedPreferences.
//   /// Вызывать после входа в аккаунт.
//   Future<void> loadSettingsFromRemote() async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//
//     final row = await Supabase.instance.client
//         .from('push_tokens')
//         .select('notif_enabled, notif_hour, notif_minute')
//         .eq('user_id', userId)
//         .maybeSingle();
//
//     if (row == null) return;
//
//     final enabled = row['notif_enabled'] as bool? ?? false;
//     final hour = row['notif_hour'] as int? ?? 18;
//     final minute = row['notif_minute'] as int? ?? 0;
//     await UserProfileService().saveNotificationSettings(enabled, hour, minute);
//   }
//
//   /// Регистрирует FCM-токен при входе в аккаунт (не меняет настройки уведомлений).
//   Future<void> registerToken() async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//
//     final token = await FirebaseMessaging.instance.getToken();
//     if (token == null) return;
//
//     final utcOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
//
//     await Supabase.instance.client.from('push_tokens').upsert(
//       {
//         'user_id': userId,
//         'fcm_token': token,
//         'utc_offset_minutes': utcOffsetMinutes,
//         'updated_at': DateTime.now().toUtc().toIso8601String(),
//       },
//       onConflict: 'user_id',
//     );
//   }
// }