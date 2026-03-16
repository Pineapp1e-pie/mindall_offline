// health_step.dart (с Provider)

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👈 добавить импорт
import 'package:health/health.dart';

import '../../data/local/repositories/local_repository.dart'; // 👈 только интерфейс
import '../../domain/models/mood_entry_draft.dart';
import '../../domain/models/health_draft.dart';
import '../../domain/services/health_service.dart';
import '../widgets/step_indicator.dart';
import '../widgets/bottom_button.dart';

import 'health_content.dart';
import 'home_container.dart';
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

  final HealthService _healthService = HealthService();
  final int _currentStep = 3;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;

    // 👇 Получаем репозиторий один раз при инициализации
    _repository = context.read<LocalRepository>();

    _loadTodayHealth();
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
    setState(() => _loading = true);

    try {
      final granted = await _healthService.requestPermissions();
      if (!granted) {
        _showError("Нет доступа к данным здоровья");
        return;
      }

      final sleep = await _healthService.getSleepMinutes();
      final steps = await _healthService.getStepAmount();

      final now = DateTime.now();
      final health = HealthDraft(
        date: DateTime(now.year, now.month, now.day),
        sleepMinutes: sleep,
        stepsAmount: steps,
        cyclePhase: null,
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
      MaterialPageRoute(
        builder: (_) => ManualHealthScreen(
          moodColor: widget.moodColor,
          initialHealth: _draft.health,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _draft = _draft.copyWith(health: result);
      });
    }
  }

  void _saveAndContinue() async {
    setState(() => _loading = true);

    try {
      await _repository.saveFullEntry(_draft);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeContainer()),
            (route) => false,
      );
    } catch (e) {
      _showError('Не удалось сохранить запись');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _loading ? null : _detectHealth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.moodColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              health == null ? "Определить" : "Обновить",
                              style: const TextStyle(
                                fontFamily: 'DotGothic',
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _navigateToManualInput,
                              child: const Text(
                                "Записать самостоятельно",
                                style: TextStyle(
                                  fontFamily: 'DotGothic',
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (health != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: HealthContent(
                              health: health,
                              source: health.source ?? 'manual',
                              moodColor: widget.moodColor,
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