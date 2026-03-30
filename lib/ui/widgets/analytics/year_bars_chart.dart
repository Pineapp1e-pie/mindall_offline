import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/chart_models.dart';

class YearBarsChart extends StatefulWidget {
  final List<MonthQuadrantData> data;

  const YearBarsChart({super.key, required this.data});

  @override
  State<YearBarsChart> createState() => _YearBarsChartState();
}

class _YearBarsChartState extends State<YearBarsChart> {
  double _scale = 1.0;

  static const _colorNegActive = Color(0xFFFF5959);
  static const _colorPosActive = Color(0xFFFFDD3B);
  static const _colorNegCalm = Color(0xFF835AFF);
  static const _colorPosCalm = Color(0xFF46FF46);

  static const _months = [
    'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
    'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
  ];

  @override
  Widget build(BuildContext context) {
    double maxTotal = 1.0;
    for (final d in widget.data) {
      if (d.total > maxTotal) maxTotal = d.total.toDouble();
    }

    final fontSize = 8.0 + 2.0 * (_scale - 1.0);
    final barWidth = (18.0 * _scale).clamp(18.0, 56.0);

    final groups = widget.data.asMap().entries.map((e) {
      final idx = e.key;
      final d = e.value;
      if (d.total == 0) {
        return BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: 1,
              color: Colors.white12,
              width: barWidth,
              borderRadius: BorderRadius.zero,
            ),
          ],
        );
      }
      final na = d.negativeActive.toDouble();
      final pa = d.positiveActive.toDouble();
      final nc = d.negativeCalm.toDouble();
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: d.total.toDouble(),
            width: barWidth,
            borderRadius: BorderRadius.zero,
            rodStackItems: [
              BarChartRodStackItem(0, na, _colorNegActive),
              BarChartRodStackItem(na, na + pa, _colorPosActive),
              BarChartRodStackItem(na + pa, na + pa + nc, _colorNegCalm),
              BarChartRodStackItem(
                  na + pa + nc, d.total.toDouble(), _colorPosCalm),
            ],
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = constraints.maxWidth * _scale;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: chartWidth,
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: groups,
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxTotal * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                          color: Colors.white12, strokeWidth: 1),
                    ),
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
                          reservedSize: 20,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= 12) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _months[idx],
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: fontSize,
                                  fontFamily: 'DotGothic',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(enabled: false),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ZoomBtn(
              icon: Icons.remove,
              enabled: _scale > 1.0,
              onTap: () =>
                  setState(() => _scale = (_scale - 1.0).clamp(1.0, 4.0)),
            ),
            const SizedBox(width: 8),
            ZoomBtn(
              icon: Icons.add,
              enabled: _scale < 4.0,
              onTap: () =>
                  setState(() => _scale = (_scale + 1.0).clamp(1.0, 4.0)),
            ),
          ],
        ),
      ],
    );
  }
}

class ZoomBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const ZoomBtn(
      {super.key,
      required this.icon,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? Colors.white38 : Colors.white12,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white70 : Colors.white24,
        ),
      ),
    );
  }
}
