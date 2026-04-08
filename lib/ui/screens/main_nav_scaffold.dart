import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/local/app_database.dart';
import '../../domain/services/health_service.dart';
import 'home_container.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key});

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
                    fontSize: 24,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}
