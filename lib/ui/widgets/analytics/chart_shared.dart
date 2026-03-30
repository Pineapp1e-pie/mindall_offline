import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/local/static/moods.dart';
import '../../../domain/models/chart_models.dart';
import '../../../domain/models/mood_entry_with_mood.dart';
import '../../assets/mood_colors.dart';

class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator(color: Colors.white70)),
    );
  }
}

class EmptyChart extends StatelessWidget {
  final String text;
  const EmptyChart({this.text = 'Нет данных'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

FlGridData chartGrid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 0.5,
      getDrawingHorizontalLine: (v) => FlLine(
        color: v.abs() < 0.01 ? Colors.white24 : Colors.white12,
        strokeWidth: v.abs() < 0.01 ? 1.5 : 1,
      ),
    );

Color dayTypeColor(DayType type) => switch (type) {
      DayType.stable => const Color(0xFF7EC8E3),
      DayType.balanced => const Color(0xFFB8A9E3),
      DayType.contrast => const Color(0xFFF4A261),
    };

class DayHourChart extends StatelessWidget {
  final List<MoodEntryWithMood> entries;
  const DayHourChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final spots = entries.map((e) {
      final hour = e.entry.createdAt.hour + e.entry.createdAt.minute / 60.0;
      final color = moodColors[e.mood.name] ?? Colors.white;
      return ScatterSpot(
        hour,
        e.mood.y.clamp(-1.0, 1.0),
        dotPainter: FlDotCirclePainter(
          radius: 7,
          color: color,
          strokeColor: Colors.transparent,
          strokeWidth: 0,
        ),
      );
    }).toList();

    final hours = entries
        .map((e) => e.entry.createdAt.hour + e.entry.createdAt.minute / 60.0);
    final rawMin = hours.reduce((a, b) => a < b ? a : b);
    final rawMax = hours.reduce((a, b) => a > b ? a : b);
    final minX = ((rawMin / 4).floor() * 4).toDouble();
    final maxX =
        ((rawMax / 4).ceil() * 4).toDouble().clamp(minX + 4, 24.0);

    return SizedBox(
      height: 160,
      child: ScatterChart(
        ScatterChartData(
          minX: minX,
          maxX: maxX,
          minY: -1.2,
          maxY: 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (v) => FlLine(
              color: v.abs() < 0.01 ? Colors.white24 : Colors.white12,
              strokeWidth: v.abs() < 0.01 ? 1.5 : 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 4,
                getTitlesWidget: (val, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${val.toInt()}:00',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'DotGothic',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          scatterSpots: spots,
          scatterTouchData: ScatterTouchData(
            enabled: true,
            touchTooltipData: ScatterTouchTooltipData(
              getTooltipItems: (spot) {
                final h = spot.x.toInt();
                final m = ((spot.x - h) * 60).round();
                final time =
                    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                return ScatterTooltipItem(
                  '$time  ${spot.y.toStringAsFixed(2)}',
                  textStyle: const TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 11,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
