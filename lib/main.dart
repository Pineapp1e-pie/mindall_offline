import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'data/local/app_database.dart';
import 'data/local/repositories/local_repository.dart';
import 'data/local/repositories/local_repository_impl.dart';
import 'data/local/static/moods_initializer.dart';
import 'data/local/static/context_tags_seed.dart';
import 'background/step_sync_worker.dart';

import 'ui/screens/home_container.dart';
import 'ui/screens/auth_screen.dart';
import 'data/remote/supabase_sync_service.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';



void main() async {
  Intl.defaultLocale = 'ru';

  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loggedIn = Supabase.instance.client.auth.currentSession != null;
  bool _wasOffline = false;

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
      if (!wasLoggedIn && data.session != null) {
        context.read<SupabaseSyncService>().syncAll();
      }
    });

    // Синхронизация когда появляется интернет
    Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final isOnline = results.any((r) => r !=

          ConnectivityResult.none);
      if (
      isOnline && _wasOffline && _loggedIn) {
        context.read<SupabaseSyncService>().syncAll();
      }
      _wasOffline = !isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _loggedIn ? const HomeContainer() : const AuthScreen(),
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
