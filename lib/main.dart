import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'data/local/app_database.dart';
import 'data/local/repositories/local_repository.dart';
import 'data/local/repositories/local_repository_impl.dart';
import 'data/local/static/moods_initializer.dart';
import 'data/local/static/context_tags_seed.dart';
import 'background/step_sync_worker.dart';
import 'domain/services/notification_service.dart';
import 'domain/services/user_profile_service.dart';

import 'ui/screens/main_nav_scaffold.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/reset_password_screen.dart';
import 'data/remote/supabase_sync_service.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';



void main() async {
  Intl.defaultLocale = 'ru';

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Supabase.initialize(
    url: 'https://bcvyypjjobivgjtswxdi.supabase.co',
    anonKey: 'sb_publishable_hoH2DPUJVXlIDjK25DEyrw_yU5JJ_8b',
  );

  final database = AppDatabase();
  final repository = LocalRepositoryImpl(database);
  final syncService = SupabaseSyncService(database);

  await MoodsInitializer(database).init();
  await ContextTagsInitializer(database).init();

  // Инициализируем WorkManager и планируем ежедневную синхронизацию шагов
  await Workmanager().initialize(callbackDispatcher);
  _scheduleStepSync();

  // Инициализируем уведомления и восстанавливаем расписание
  await NotificationService().init();
  await _restoreNotificationSchedule();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalRepository>(create: (_) => repository),
        Provider<SupabaseSyncService>(create: (_) => syncService),
      ],
      child: const MyApp(),
    ),
  );
}

/// Планирует одноразовую задачу на сегодня в 23:59.
/// После выполнения задача перепланирует себя на следующие сутки.
void _scheduleStepSync() {
  final now = DateTime.now();
  final targetTime = DateTime(now.year, now.month, now.day, 23, 30);

  // Если 23:59 уже прошло — планируем на завтра
  final delay = targetTime.isAfter(now)
      ? targetTime.difference(now)
      : targetTime.add(const Duration(days: 1)).difference(now);

  Workmanager().registerOneOffTask(
    'stepSync_${now.year}_${now.month}_${now.day}', // уникальное имя каждый день
    stepSyncTaskName, // 'stepSync2330Task'
    initialDelay: delay,
    constraints: Constraints(
      networkType: NetworkType.notRequired,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  print('Синхронизация шагов запланирована через ${delay.inMinutes} минут');
}

/// Восстанавливает расписание уведомлений после перезапуска приложения.
Future<void> _restoreNotificationSchedule() async {
  final profileService = UserProfileService();
  final enabled = await profileService.loadNotificationsEnabled();
  if (!enabled) return;
  final hour = await profileService.loadNotificationHour();
  final minute = await profileService.loadNotificationMinute();
  await NotificationService().scheduleDailyReminder(hour, minute);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loggedIn = Supabase.instance.client.auth.currentSession != null;
  bool _wasOffline = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();

    // Синхронизация при старте если уже залогинены
    if (_loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SupabaseSyncService>().syncAll();
      });
    }

    // Синхронизация при входе в аккаунт
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final wasLoggedIn = _loggedIn;
      setState(() => _loggedIn = data.session != null);

      if (data.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
            (_) => false,
          );
        });
        return;
      }

      if (!wasLoggedIn && data.session != null) {
        context.read<SupabaseSyncService>().syncAll();
      }
    });

    // Синхронизация когда появляется интернет
    Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && _wasOffline && _loggedIn) {
        context.read<SupabaseSyncService>().syncAll();
      }
      _wasOffline = !isOnline;
    });

    // Deep link обработка
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Ссылка при холодном старте (приложение было закрыто)
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Ссылка пока приложение работает
    _linkSub = appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  Future<void> _handleDeepLink(Uri uri) async {
    try {
      final refreshToken = uri.queryParameters['refresh_token'];

      if (refreshToken != null) {
        // Токены в query params — устаревший implicit flow
        await Supabase.instance.client.auth.setSession(refreshToken);
        // Навигация обрабатывается в onAuthStateChange по типу события
        return;
      }

      // PKCE flow — токены в фрагменте или code в query params
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      // Навигация обрабатывается в onAuthStateChange по типу события
    } catch (_) {
      // игнорируем ошибки
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      home: _loggedIn ? const MainNavScaffold() : const AuthScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
    );
  }
}
