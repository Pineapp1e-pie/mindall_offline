import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';
import '../../domain/models/health_draft.dart';
import '../../data/local/tables/context_tags.dart';
import '../widgets/tag_section.dart';

class ManualHealthScreen extends StatefulWidget {
  final Color moodColor;
  final HealthDraft? initialHealth;
  final bool isFemale;
  final VoidCallback? onUpdateCycle;

  const ManualHealthScreen({
    super.key,
    required this.moodColor,
    this.initialHealth,
    this.isFemale = false,
    this.onUpdateCycle,
  });

  @override
  State<ManualHealthScreen> createState() => _ManualHealthScreenState();
}

class _ManualHealthScreenState extends State<ManualHealthScreen> {

  final _sleepHoursController = TextEditingController();
  final _sleepMinutesController = TextEditingController();
  final _activityController = TextEditingController();

  int? _selectedCycleId;

  static const int _cycleOffset = 400;

  late List<ContextTag> _cycleTags;

  @override
  void initState() {
    super.initState();

    _cycleTags = CyclePhase.values.map((phase) {
      return ContextTag(
        id: phase.index + _cycleOffset,
        name: phase.name,
        type: ContextTagType.activity,
        isCustom: false,
        isActive: false,
      );
    }).toList();

    if (widget.initialHealth != null) {
      final health = widget.initialHealth!;

      if (health.sleepMinutes != null) {
        final hours = health.sleepMinutes! ~/ 60;
        final minutes = health.sleepMinutes! % 60;

        _sleepHoursController.text = hours.toString();
        _sleepMinutesController.text = minutes.toString();
      }

      if (health.stepsAmount != null) {
        _activityController.text = health.stepsAmount.toString();
      }

      if (health.cyclePhase != null) {
        _selectedCycleId =
            health.cyclePhase!.index + _cycleOffset;
      }
    }
  }

  void _handleCycleToggle(int id) {
    setState(() {
      _selectedCycleId = _selectedCycleId == id ? null : id;
    });
  }

  HealthDraft _buildDraft() {
    final hours = int.tryParse(_sleepHoursController.text);
    final minutes = int.tryParse(_sleepMinutesController.text);

    int? sleepMinutes;

    if (hours != null || minutes != null) {
      sleepMinutes = (hours ?? 0) * 60 + (minutes ?? 0);
    }

    final steps =
    int.tryParse(_activityController.text);

    CyclePhase? cycle;

    if (_selectedCycleId != null) {
      final index = _selectedCycleId! - _cycleOffset;
      cycle = CyclePhase.values[index];
    }

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);

    return HealthDraft(
      date: date,
      sleepMinutes: sleepMinutes,
      stepsAmount: steps,
      cyclePhase: cycle,
      source: 'manual',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Укажите здоровье',
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Сон',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'DotGothic',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sleepHoursController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: widget.moodColor,
                            decoration: const InputDecoration(
                              hintText: "Часы",
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _sleepMinutesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: widget.moodColor,
                            decoration: const InputDecoration(
                              hintText: "Минуты",
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Шаги',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'DotGothic',
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _activityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: widget.moodColor,
                    ),

                    const SizedBox(height: 32),

                    if (widget.isFemale) ...[
                      TagSection(
                        title: 'Фаза цикла',
                        tags: _cycleTags,
                        selectedIds: _selectedCycleId != null
                            ? [_selectedCycleId!]
                            : [],
                        onToggle: _handleCycleToggle,
                      ),
                      if (widget.onUpdateCycle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: widget.onUpdateCycle,
                            child: const Text(
                              'Обновить данные цикла',
                              style: TextStyle(
                                fontFamily: 'DotGothic',
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
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
                  onPressed: () {
                    final draft = _buildDraft();
                    Navigator.pop(context, draft);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.moodColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
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
}
