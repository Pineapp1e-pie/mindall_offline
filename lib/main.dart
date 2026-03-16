import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';


import 'data/local/app_database.dart';
import 'data/local/repositories/local_repository.dart';
import 'data/local/repositories/local_repository_impl.dart';
import 'data/local/static/moods_initializer.dart';
import 'data/local/static/context_tags_seed.dart';

import 'ui/screens/home_container.dart';
import 'package:intl/intl.dart';



void main() async {
  Intl.defaultLocale = 'ru';

  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = LocalRepositoryImpl(database);

  await MoodsInitializer(database).init();
  await ContextTagsInitializer(database).init();

  runApp(
    Provider<LocalRepository>(
      create: (_) => repository,
      child: const MyApp(),
    ),
      );
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
