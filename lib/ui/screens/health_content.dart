import 'package:flutter/material.dart';
import '../../domain/models/health_draft.dart';

class HealthContent extends StatelessWidget {
  final HealthDraft health;
  final String source;
  final Color moodColor;

  const HealthContent({
    super.key,
    required this.health,
    required this.source,
    required this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    final sleep = health.sleepMinutes != null
        ? "${health.sleepMinutes! ~/ 60}ч ${health.sleepMinutes! % 60}м"
        : "НЕ УКАЗАНО";

    final steps = health.stepsAmount != null
        ? "${health.stepsAmount}"
        : "НЕ УКАЗАНО";

    final cycle = health.cyclePhase?.name ?? "НЕ УКАЗАНО";

    return Column(
      children: [
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF18221C),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row("СОН", sleep),
              const SizedBox(height: 20),
              _row("ШАГИ", steps),
              const SizedBox(height: 20),
              _row("ЦИКЛ", cycle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1511),
            border: Border.all(
              color: Colors.white30,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'DotGothic',
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}