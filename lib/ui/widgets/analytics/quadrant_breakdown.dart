import 'package:flutter/material.dart';

import '../../../data/local/static/moods.dart';
import '../../assets/category_colors.dart';

class QuadrantBreakdown extends StatelessWidget {
  final Future<Map<MoodCategory, int>> future;

  const QuadrantBreakdown({super.key, required this.future});

  static const _groups = [
    (label: 'Позитивное', high: MoodCategory.positiveActive, low: MoodCategory.positiveCalm),
    (label: 'Негативное', high: MoodCategory.negativeActive, low: MoodCategory.negativeCalm),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<MoodCategory, int>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final counts = snapshot.data!;
        final total = counts.values.fold(0, (a, b) => a + b);
        if (total == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _groups.map((g) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${g.label}:',
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _bar(counts, total, g.high, 'Высокая энергия'),
                  const SizedBox(height: 4),
                  _bar(counts, total, g.low, 'Низкая энергия'),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _bar(Map<MoodCategory, int> counts, int total, MoodCategory cat, String label) {
    final pct = (counts[cat] ?? 0) / total;
    final color = colorForCategory(cat);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 10,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(height: 8, color: Colors.white12),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(height: 8, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
