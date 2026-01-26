import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/local/app_database.dart';
import 'data/local/static/context_tags_seed.dart';
import 'data/local/static/moods_initializer.dart';
import 'data/local/debug/fake_data_generator.dart';

import 'ui/screens/home_container.dart';
import 'package:intl/intl.dart';

void main() async {
  Intl.defaultLocale = 'ru';

  WidgetsFlutterBinding.ensureInitialized();


  final db = AppDatabase();

  // 1️⃣ СИДЫ (выполняется безопасно, без дублей)
  await MoodsInitializer(db).init();
  await ContextTagsInitializer(db).init();


  runApp(const MyApp());
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
