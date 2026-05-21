import 'package:mindall_offline/ui/app_route.dart';
// health_step.dart (с Provider)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/repositories/local_repository.dart';
import '../../data/remote/supabase_sync_service.dart';
import '../../domain/models/mood_entry_draft.dart';
import '../../domain/models/health_draft.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/crisis_detector.dart';
import '../../domain/services/health_service.dart';
import '../../domain/services/subscription_service.dart';
import '../../domain/services/user_profile_service.dart';
import '../../domain/services/cycle_calculator.dart';
import '../../domain/services/daily_mood_analyzer.dart';
import '../app_route.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/step_indicator.dart';
import '../widgets/bottom_button.dart';

import 'cycle_setup_screen.dart';
import 'health_content.dart';
import 'main_nav_scaffold.dart';
import 'manual_health_screen.dart';

class HealthStepScreen extends StatefulWidget {
  final MoodEntryDraft draft;
  final Color moodColor;

  const HealthStepScreen({
    super.key,
    required this.draft,
    required this.moodColor,
  });

  @override
  State<HealthStepScreen> createState() => _HealthStepScreenState();
}

class _HealthStepScreenState extends State<HealthStepScreen> {
  late MoodEntryDraft _draft;
  late LocalRepository _repository; // 👈

  bool _loading = false;
  bool _isLoadingExisting = true;

  late final HealthService _healthService;
  UserProfile? _userProfile;
  final int _currentStep = 3;

  bool get _isToday {
    final target = _draft.entryDate ?? DateTime.now();
    final now = DateTime.now();
    return target.year == now.year &&
        target.month == now.month &&
        target.day == now.day;
  }

  bool get _shouldQueueHealthDeletion {
    final health = _draft.health;
    return _draft.editingEntryId != null &&
        (health == null ||
            (health.sleepMinutes == null &&
                health.stepsAmount == null &&
                health.cyclePhase == null));
  }

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _healthService = HealthService(context.read<SubscriptionService>());

    // 👇 Получаем репозиторий один раз при инициализации
    _repository = context.read<LocalRepository>();

    if (_draft.editingEntryId == null) {
      _loadTodayHealth();
    } else {
      _isLoadingExisting = false;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileService = context.read<UserProfileService>();

    if (profileService.gender == null) {
      // Первый запуск — спросить пол
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGenderDialog());
    } else {
      final profile = UserProfile(
        gender: profileService.gender!,
        username: profileService.username,
        cycleSettings: profileService.cycleSettings,
        subscriptionType: profileService.subscriptionType,
      );
      setState(() => _userProfile = profile);
      // Если женщина и нет настроек цикла — предложить настроить
      if (profile.isFemale && profile.cycleSettings == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openCycleSetup());
      }
    }
  }

  Future<void> _showGenderDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18221C),
        title: const Text(
          'Ваш пол',
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _genderOption(ctx, 'Женский', Gender.female),
            const SizedBox(height: 8),
            _genderOption(ctx, 'Мужской', Gender.male),
            const SizedBox(height: 8),
            _genderOption(
              ctx,
              'Предпочитаю не указывать',
              Gender.preferNotToSay,
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderOption(BuildContext ctx, String label, Gender gender) {
    return GestureDetector(
      onTap: () async {
        final profileService = context.read<UserProfileService>();
        await profileService.saveGender(gender);
        final profile = UserProfile(
          gender: gender,
          subscriptionType: profileService.subscriptionType,
        );
        if (!mounted) return;
        setState(() => _userProfile = profile);
        if (!ctx.mounted) return;
        Navigator.of(ctx).pop();
        if (gender == Gender.female) {
          _openCycleSetup();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _openCycleSetup() async {
    final settings = await Navigator.push<CycleSettings>(
      context,
      AppRoute(
        page: CycleSetupScreen(
          moodColor: widget.moodColor,
          initial: _userProfile?.cycleSettings,
        ),
      ),
    );

    if (settings != null && mounted) {
      final updatedProfile = UserProfile(
        gender: _userProfile?.gender ?? Gender.female,
        username: _userProfile?.username,
        cycleSettings: settings,
        subscriptionType:
            _userProfile?.subscriptionType ??
            context.read<UserProfileService>().subscriptionType,
      );
      setState(() {
        _userProfile = updatedProfile;
        // Обновить фазу в черновике для даты записи, а не сегодня
        final entryDate = _draft.entryDate ?? DateTime.now();
        final phase = CycleCalculator.calculate(settings, date: entryDate);
        _draft = _draft.copyWith(
          health:
              _draft.health?.copyWith(cyclePhase: phase) ??
              HealthDraft(
                date: DateTime(entryDate.year, entryDate.month, entryDate.day),
                cyclePhase: phase,
                source: 'auto',
              ),
        );
      });
    }
  }

  Future<void> _loadTodayHealth() async {
    setState(() => _isLoadingExisting = true);

    try {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      final existing = await _repository.getHealthDataForDay(date);

      if (existing != null) {
        setState(() {
          _draft = _draft.copyWith(
            health: HealthDraft(
              date: existing.date,
              sleepMinutes: existing.sleepMinutes,
              stepsAmount: existing.stepsAmount,
              cyclePhase: existing.cyclePhase,
              source: existing.source ?? 'manual',
            ),
          );
        });
      }
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
    } finally {
      setState(() => _isLoadingExisting = false);
    }
  }

  Future<void> _detectHealth() async {
    final hasAccess = context.read<SubscriptionService>().checkAccess(
      SubscriptionFeature.autoHealthData,
    );
    if (!hasAccess) {
      _showPaywall();
      return;
    }

    setState(() => _loading = true);

    try {
      final granted = await _healthService.requestPermissions();
      if (!granted) {
        _showError(
          "Нет доступа к данным здоровья.\nПодключите Health Connect.",
        );
        return;
      }

      final target = _draft.entryDate ?? DateTime.now();

      final sleep = await _healthService.getSleepMinutes(date: target);
      final steps = await _healthService.getStepAmount(date: target);
      final cycleSettings = _userProfile?.cycleSettings;
      final cyclePhase = (_isToday && cycleSettings != null)
          ? CycleCalculator.calculate(cycleSettings)
          : _draft.health?.cyclePhase;

      final health = HealthDraft(
        date: DateTime(target.year, target.month, target.day),
        sleepMinutes: sleep,
        stepsAmount: steps,
        cyclePhase: cyclePhase,
        source: "auto",
      );

      setState(() {
        _draft = _draft.copyWith(health: health);
      });
    } catch (e) {
      _showError("Ошибка получения данных: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _navigateToManualInput() async {
    final result = await Navigator.push(
      context,
      AppRoute(
        page: ManualHealthScreen(
          moodColor: widget.moodColor,
          initialHealth: _draft.health,
          isFemale: _userProfile?.isFemale ?? false,
          onUpdateCycle: _userProfile?.isFemale == true
              ? _openCycleSetup
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _draft = _draft.copyWith(health: result);
      });
    }
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          const Padding(padding: EdgeInsets.all(16), child: PaywallWidget()),
    );
  }

  void _saveAndContinue() async {
    setState(() => _loading = true);

    // Захватываем всё из context ДО первого await
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final achievementSvc = userId.isNotEmpty
        ? context.read<AchievementService>()
        : null;

    try {
      final entryDate = _draft.entryDate ?? DateTime.now();
      final shouldQueueHealthDeletion = _shouldQueueHealthDeletion;

      if (_draft.editingEntryId != null) {
        await _repository.updateFullEntry(_draft.editingEntryId!, _draft);
      } else {
        await _repository.saveFullEntry(_draft);
      }

      await DailyMoodAnalyzer(_repository).analyzeDay(entryDate);

      // Проверяем и записываем ачивки независимо от состояния виджета
      if (achievementSvc != null) {
        final newAchievements = await achievementSvc.checkAfterEntrySaved(
          userId,
        );

        if (mounted) {
          for (final achievement in newAchievements) {
            if (!mounted) break;
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AchievementUnlockDialog(achievement: achievement),
            );
          }
        }
      }

      if (!mounted) return;

      final crisisLevel = await _getCrisisLevel(entryDate);
      final syncSvc = context.read<SupabaseSyncService>();

      if (shouldQueueHealthDeletion) {
        await syncSvc.queueHealthDeletion(entryDate);
      }

      if (!mounted) return;

      // Фоновая синхронизация — не блокируем UI
      unawaited(
        syncSvc.syncAll().catchError(
          (Object e) => print('[Sync] ошибка после сохранения записи: $e'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        AppRoute(page: MainNavScaffold(crisisLevel: crisisLevel)),
        (route) => false,
      );
    } catch (e) {
      _showError('Не удалось сохранить запись');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<CrisisLevel> _getCrisisLevel(DateTime entryDate) async {
    // Триггерные слова — наивысший приоритет
    if (CrisisDetector.detect(_draft.note)) return CrisisLevel.crisis;

    // Стрик негативных дней
    final streak = await _countNegativeStreak(entryDate);
    if (streak >= 7) return CrisisLevel.urgentStreak;
    if (streak >= 3) return CrisisLevel.softStreak;

    return CrisisLevel.none;
  }

  /// Считает сколько дней подряд (включая сегодня) avgX < 0.
  Future<int> _countNegativeStreak(DateTime today) async {
    final todayNorm = DateTime(today.year, today.month, today.day);
    final from = todayNorm.subtract(const Duration(days: 14));

    final stats = await _repository.getDailyMoodStats(from, todayNorm);

    int streak = 0;
    for (int i = stats.length - 1; i >= 0; i--) {
      final stat = stats[i];
      final statDay = DateTime(stat.date.year, stat.date.month, stat.date.day);
      final expected = todayNorm.subtract(Duration(days: streak));
      if (statDay != expected) break;
      if (stat.avgX >= 0) break;
      streak++;
    }

    return streak;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAccess = context.watch<SubscriptionService>().checkAccess(
      SubscriptionFeature.healthData,
    );
    if (!hasAccess) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E1511),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _draft),
          ),
        ),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: PaywallWidget()),
          ),
        ),
      );
    }

    final health = _draft.health;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _draft),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _Header(currentStep: _currentStep),

                  if (_isLoadingExisting)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _detectHealth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.moodColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            health == null
                                ? "Определить"
                                : _isToday
                                ? "Обновить"
                                : "Обновить сон и шаги",
                            style: const TextStyle(
                              fontFamily: 'DotGothic',
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _navigateToManualInput,
                      child: const Center(
                        child: Text(
                          "Записать самостоятельно / редактировать",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DotGothic',
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    if (health != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: HealthContent(
                              health: health,
                              source: health.source,
                              moodColor: widget.moodColor,
                              showCycle:
                                  _userProfile?.isFemale == true &&
                                  _userProfile?.cycleSettings != null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          BottomButton(
            text: 'Сохранить',
            color: widget.moodColor,
            onTap: _saveAndContinue,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int currentStep;
  const _Header({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          StepIndicator(currentStep: currentStep),
          const SizedBox(height: 24),
          const Text(
            'Как сегодня\nсо здоровьем?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
