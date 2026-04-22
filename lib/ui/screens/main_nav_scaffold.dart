import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/app_database.dart';
import '../../domain/models/achievement.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/crisis_detector.dart';
import '../../domain/services/health_service.dart';
import '../widgets/achievement_popup.dart';
import 'home_container.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class MainNavScaffold extends StatefulWidget {
  final CrisisLevel crisisLevel;

  const MainNavScaffold({
    super.key,
    this.crisisLevel = CrisisLevel.none,
  });

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _healthService = HealthService();

  final _screens = const [
    HomeContainer(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Показываем crisis-диалог (если есть)
      if (widget.crisisLevel != CrisisLevel.none) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SupportDialog(level: widget.crisisLevel),
        );
      }

      if (!mounted) return;

      // Миграция существующих пользователей: инициализируем ачивки и проверяем
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? '';
      if (userId.isEmpty) return;

      final newAchievements = await context
          .read<AchievementService>()
          .initIfNeeded(userId);

      for (final achievement in newAchievements) {
        if (!mounted) break;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AchievementUnlockDialog(achievement: achievement),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentlyUpdateSteps();
    }
  }

  Future<void> _silentlyUpdateSteps() async {
    try {
      final db = AppDatabase();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Обновляем только если есть запись здоровья за сегодня
      final existing = await (db.select(db.healthData)
            ..where((h) => h.date.equals(todayStart)))
          .getSingleOrNull();

      if (existing == null) return;

      final steps = await _healthService.getStepAmount(date: today);
      if (steps == null) return;

      await db.into(db.healthData).insertOnConflictUpdate(
        HealthDataCompanion.insert(
          date: todayStart,
          sleepMinutes: Value(existing.sleepMinutes),
          stepsAmount: Value(steps),
          cyclePhase: Value(existing.cyclePhase),
          source: const Value('auto'),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomMenu(
        currentIndex: _currentIndex,
        onIndexChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomMenu extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _BottomMenu({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: const Color(0xFF0E1511),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomIcon(
            svgPath: 'lib/ui/assets/pixelariticons_svg/user.svg',
            isActive: currentIndex == 2,
            onTap: () => onIndexChanged(2),
          ),
          _BottomIcon(
            label: '+',
            isActive: currentIndex == 0,
            onTap: () => onIndexChanged(0),
          ),
          _BottomIcon(
            svgPath: 'lib/ui/assets/pixelariticons_svg/analytics.svg',
            isActive: currentIndex == 1,
            onTap: () => onIndexChanged(1),
          ),
        ],
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final String? svgPath;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;

  const _BottomIcon({
    this.svgPath,
    this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Center(
          child: svgPath != null
              ? SvgPicture.asset(
                  svgPath!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    isActive ? Colors.white : Colors.white54,
                    BlendMode.srcIn,
                  ),
                )
              : Text(
                  label ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Диалог поддержки ────────────────────────────────────────────────────────

class _SupportDialog extends StatefulWidget {
  final CrisisLevel level;
  const _SupportDialog({required this.level});

  @override
  State<_SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<_SupportDialog> {
  static const _phone = '8-800-2000-122';
  bool _copied = false;

  String get _title {
    return widget.level == CrisisLevel.softStreak ? 'Как ты?' : 'Мы рядом';
  }

  String get _message {
    switch (widget.level) {
      case CrisisLevel.softStreak:
        return 'Похоже, последние дни даются непросто. '
            'Иногда помогает немного замедлиться, выйти на прогулку или поговорить с кем-то';
         case CrisisLevel.urgentStreak:
        return 'Похоже, это состояние держится уже какое-то время. '
            'В такие моменты важно не оставаться совсем одному. Можно поговорить с близким или обратиться за поддержкой. Это нормально)';
      case CrisisLevel.crisis:
        return 'Если сейчас совсем тяжело, не оставайся с этим один на один. '
            'Можно написать кому-то из близких или поговорить со специалистом';
      case CrisisLevel.none:
        return '';
    }
  }

  bool get _showPhone =>
      widget.level == CrisisLevel.urgentStreak ||
      widget.level == CrisisLevel.crisis;

  Color get _accentColor => widget.level == CrisisLevel.softStreak
      ? const Color(0xFF7EB8D4)   // спокойный голубой
      : const Color(0xFFD49C7E);  // более насыщенный синий

  Future<void> _copyPhone() async {
    await Clipboard.setData(const ClipboardData(text: _phone));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1511),
          border: Border.all(color: _accentColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              _title,
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 20,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 14),

            // Сообщение
            Text(
              _message,
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 14,
                color: Colors.white,
                height: 1.7,
              ),
            ),

            // Блок с номером телефона
            if (_showPhone) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: _accentColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Телефон доверия',
                      style: TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 12,
                        color: _accentColor.withOpacity(0.8),
                        ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _phone,
                      style: const TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 24,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'бесплатно · круглосуточно',
                      style: TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _copied ? null : _copyPhone,
                      child: Text(
                        _copied ? '✓ Скопировано' : 'Скопировать номер',
                        style: TextStyle(
                          fontFamily: 'DotGothic',
                          fontSize: 13,
                          color: _copied
                              ? Colors.white38
                              : _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Кнопка
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: _accentColor,
                child: const Text(
                  'Хорошо, спасибо',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
