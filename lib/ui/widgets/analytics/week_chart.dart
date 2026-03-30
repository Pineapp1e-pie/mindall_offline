import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/chart_models.dart';
import 'chart_shared.dart';
import 'day_type_legend.dart';

class WeekChart extends StatelessWidget {
  final List<DayStats> dayStats;
  final DateTime weekStart;
  final void Function(DateTime)? onDayTap;

  const WeekChart({
    super.key,
    required this.dayStats,
    required this.weekStart,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, DayStats> byWeekday = {
      for (final ds in dayStats) ds.date.weekday: ds,
    };

    final spots = <FlSpot>[
      for (var wd = 1; wd <= 7; wd++)
        if (byWeekday.containsKey(wd))
          FlSpot((wd - 1).toDouble(), byWeekday[wd]!.avgMood.clamp(-1.0, 1.0)),
    ];

    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: -1.3,
              maxY: 1.3,
              gridData: chartGrid(),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx > 6) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          labels[idx],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontFamily: 'DotGothic',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1A1A2E),
                  getTooltipItems: (spots) => spots.map((spot) {
                    return LineTooltipItem(
                      spot.y.toStringAsFixed(2),
                      const TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
                getTouchedSpotIndicator: (_, idxs) => idxs
                    .map((_) => TouchedSpotIndicatorData(
                          const FlLine(
                              color: Colors.white38, strokeWidth: 1),
                          FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 9,
                              color: Colors.white24,
                              strokeWidth: 2,
                              strokeColor: Colors.white70,
                            ),
                          ),
                        ))
                    .toList(),
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;
                  final spot = response?.lineBarSpots?.firstOrNull;
                  if (spot == null) return;
                  final tappedDate = DateTime(
                    weekStart.year,
                    weekStart.month,
                    weekStart.day,
                  ).add(Duration(days: spot.x.toInt()));
                  onDayTap?.call(tappedDate);
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: spots.length > 2,
                  curveSmoothness: 0.3,
                  color: Colors.white24,
                  barWidth: 1.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, idx) {
                      final wd = spots[idx].x.toInt() + 1;
                      final ds = byWeekday[wd];
                      final color = ds != null
                          ? dayTypeColor(ds.dayType)
                          : Colors.white24;
                      return FlDotCirclePainter(
                        radius: 6,
                        color: color,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const DayTypeLegend(),
      ],
    );
  }
}
