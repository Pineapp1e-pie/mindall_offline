import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/cycle_calculator.dart';
import '../../domain/services/user_profile_service.dart';
import '../../domain/models/health_draft.dart';

class CycleSetupScreen extends StatefulWidget {
  final Color moodColor;
  final CycleSettings? initial;

  const CycleSetupScreen({
    super.key,
    required this.moodColor,
    this.initial,
  });

  @override
  State<CycleSetupScreen> createState() => _CycleSetupScreenState();
}

class _CycleSetupScreenState extends State<CycleSetupScreen> {
  final _profileService = UserProfileService();

  DateTime? _lastPeriodStart;
  int _cycleLength = 28;
  int _periodDuration = 5;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _lastPeriodStart = widget.initial!.lastPeriodStart;
      _cycleLength = widget.initial!.cycleLengthDays;
      _periodDuration = widget.initial!.periodDurationDays;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: widget.moodColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _lastPeriodStart = picked);
    }
  }

  CyclePhase? get _calculatedPhase {
    if (_lastPeriodStart == null) return null;
    return CycleCalculator.calculate(CycleSettings(
      lastPeriodStart: _lastPeriodStart!,
      cycleLengthDays: _cycleLength,
      periodDurationDays: _periodDuration,
    ));
  }

  String _phaseName(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstruation:
        return 'Менструация';
      case CyclePhase.follicular:
        return 'Фолликулярная';
      case CyclePhase.ovulation:
        return 'Овуляция';
      case CyclePhase.luteal:
        return 'Лютеиновая';
    }
  }

  Future<void> _save() async {
    if (_lastPeriodStart == null) return;
    final settings = CycleSettings(
      lastPeriodStart: _lastPeriodStart!,
      cycleLengthDays: _cycleLength,
      periodDurationDays: _periodDuration,
    );
    await _profileService.saveCycleSettings(settings);
    if (!mounted) return;
    Navigator.pop(context, settings);
  }

  @override
  Widget build(BuildContext context) {
    final phase = _calculatedPhase;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Данные цикла',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'DotGothic',
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Начало последней менструации'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18221C),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          _lastPeriodStart != null
                              ? DateFormat('d MMMM yyyy', 'ru').format(_lastPeriodStart!)
                              : 'Выбрать дату',
                          style: TextStyle(
                            fontFamily: 'DotGothic',
                            color: _lastPeriodStart != null
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _label('Длина цикла (дней)'),
                    const SizedBox(height: 8),
                    _stepper(
                      value: _cycleLength,
                      min: 21,
                      max: 45,
                      onChanged: (v) => setState(() => _cycleLength = v),
                    ),
                    const SizedBox(height: 32),
                    _label('Длительность менструации (дней)'),
                    const SizedBox(height: 8),
                    _stepper(
                      value: _periodDuration,
                      min: 2,
                      max: 10,
                      onChanged: (v) => setState(() => _periodDuration = v),
                    ),
                    if (phase != null) ...[
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: widget.moodColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ТЕКУЩАЯ ФАЗА',
                              style: TextStyle(
                                fontFamily: 'DotGothic',
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _phaseName(phase),
                              style: TextStyle(
                                fontFamily: 'DotGothic',
                                color: widget.moodColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _lastPeriodStart != null ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.moodColor,
                    disabledBackgroundColor: Colors.white12,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontFamily: 'DotGothic',
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontFamily: 'DotGothic',
        fontSize: 13,
      ),
    );
  }

  Widget _stepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        _stepBtn(Icons.remove, () {
          if (value > min) onChanged(value - 1);
        }),
        const SizedBox(width: 16),
        Text(
          '$value',
          style: const TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        const SizedBox(width: 16),
        _stepBtn(Icons.add, () {
          if (value < max) onChanged(value + 1);
        }),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
