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
import 'package:intl/intl.dart';



void main() async {
  Intl.defaultLocale = 'ru';

  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = LocalRepositoryImpl(database);

  await MoodsInitializer(database).init();
  await ContextTagsInitializer(database).init();

  // Инициализируем WorkManager и планируем ежедневную синхронизацию шагов
  await Workmanager().initialize(callbackDispatcher);
  _scheduleStepSync();

  runApp(
    Provider<LocalRepository>(
      create: (_) => repository,
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeContainer(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Русский
        Locale('en', 'US'), // Английский (опционально)
      ],
      locale: const Locale('ru', 'RU'), // Принудительно русский

    );
  }
}
