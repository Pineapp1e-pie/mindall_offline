import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'background/step_sync_worker.dart';
import 'data/local/app_database.dart';
import 'data/local/repositories/local_repository.dart';
import 'data/local/repositories/local_repository_impl.dart';
import 'data/local/static/context_tags_seed.dart';
import 'data/local/static/moods_initializer.dart';
import 'domain/services/achievement_service.dart';
import 'domain/services/notification_service.dart';
import 'domain/services/user_profile_service.dart';

import 'ui/screens/main_nav_scaffold.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  Intl.defaultLocale = 'ru';

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );


  final database = AppDatabase();

  final repository = LocalRepositoryImpl(database);

  final achievementService = AchievementService(repository);

  final profileService = UserProfileService();

  await profileService.init();

  await MoodsInitializer(database).init();

  await ContextTagsInitializer(database).init();

  await initWorkManager();
  //
  // await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalRepository>(
          create: (_) => repository,
        ),
        Provider<AchievementService>(
          create: (_) => achievementService,
        ),
        ChangeNotifierProvider<UserProfileService>(
          create: (_) => profileService,
        ),
      ],
      child: MyApp(
        profileService: profileService,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final UserProfileService profileService;

  const MyApp({
    super.key,
    required this.profileService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: profileService.isFirstLaunch
          ? const OnboardingScreen()
          : const MainNavScaffold(),

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