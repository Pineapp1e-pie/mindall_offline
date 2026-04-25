import 'package:mindall/ui/app_route.dart';
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/local/app_database.dart';
import 'data/local/repositories/local_repository.dart';
import 'data/local/repositories/local_repository_impl.dart';
import 'data/local/static/moods_initializer.dart';
import 'data/local/static/context_tags_seed.dart';
import 'background/step_sync_worker.dart';
import 'domain/services/achievement_service.dart';
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

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: 'https://bcvyypjjobivgjtswxdi.supabase.co',
    anonKey: 'sb_publishable_hoH2DPUJVXlIDjK25DEyrw_yU5JJ_8b',
  );

  final database = AppDatabase();
  final repository = LocalRepositoryImpl(database);
  final achievementService = AchievementService(repository);
  final syncService = SupabaseSyncService(database);
  final profileService = UserProfileService();
  await profileService.init();

  await MoodsInitializer(database).init();
  await ContextTagsInitializer(database).init();

  // Инициализируем WorkManager для синхронизации шагов
  await initWorkManager();

  // Инициализируем FCM-уведомления
  await NotificationService().init();

  // Регистрируем FCM-токен если пользователь уже залогинен (не блокируем запуск)
  if (Supabase.instance.client.auth.currentSession != null) {
    NotificationService().registerToken();
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalRepository>(create: (_) => repository),
        Provider<SupabaseSyncService>(create: (_) => syncService),
        Provider<AchievementService>(create: (_) => achievementService),
        ChangeNotifierProvider<UserProfileService>(create: (_) => profileService),
      ],
      child: const MyApp(),
    ),
  );
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
            AppRoute(page: const ResetPasswordScreen()),
            (_) => false,
          );
        });
        return;
      }

      if (!wasLoggedIn && data.session != null) {
        context.read<SupabaseSyncService>().syncAll();
        NotificationService().registerToken();
        NotificationService().loadSettingsFromRemote();
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
        await Supabase.instance.client.auth.setSession(refreshToken);
        return;
      }

      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {
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
