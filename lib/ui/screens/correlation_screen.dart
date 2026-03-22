import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/local/repositories/local_repository.dart';
import '../../domain/models/chart_models.dart';
import '../../domain/services/analytics_service.dart';
import '../assets/mood_colors.dart';

enum CorrelationType { sleep, activity, weather, cycle }

class CorrelationScreen extends StatefulWidget {
  final CorrelationType type;

  const CorrelationScreen({super.key, required this.type});

  @override
  State<CorrelationScreen> createState() => _CorrelationScreenState();
}

enum _Period { week, month, year }

class _CorrelationScreenState extends State<CorrelationScreen> {
  _Period _period = _Period.week;
  late AnalyticsService _service;
  late Future<List<ScatterPoint>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _service = AnalyticsService(context.read<LocalRepository>());
      _future = _load();
      _initialized = true;
    }
  }

  DateTimeRange get _range {
    final now = DateTime.now();
    return switch (_period) {
      _Period.week =>
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      _Period.month =>
        DateTimeRange(start: DateTime(now.year, now.month - 1, now.day), end: now),
      _Period.year =>
        DateTimeRange(start: DateTime(now.year - 1, now.month, now.day), end: now),
    };
  }

  Future<List<ScatterPoint>> _load() {
    final r = _range;
    return switch (widget.type) {
      CorrelationType.sleep => _service.getMoodVsSleep(r.start, r.end),
      CorrelationType.activity => _service.getMoodVsActivity(r.start, r.end),
      CorrelationType.weather => _service.getMoodVsWeather(r.start, r.end),
      CorrelationType.cycle => _service.getMoodVsCycle(r.start, r.end),
    };
  }

  void _setPeriod(_Period p) {
    setState(() {
      _period = p;
      _future = _load();
    });
  }

  String get _title => switch (widget.type) {
        CorrelationType.sleep => 'Настроение : Сон (ч)',
        CorrelationType.activity => 'Настроение : Активность',
        CorrelationType.weather => 'Настроение : Погода (°C)',
        CorrelationType.cycle => 'Цикл : Настроение',
      };

  String get _xLabel => switch (widget.type) {
        CorrelationType.sleep => 'ч сна',
        CorrelationType.activity => 'шагов',
        CorrelationType.weather => '°C',
        CorrelationType.cycle => 'настроение',
      };

  String get _emptyText => switch (widget.type) {
        CorrelationType.sleep => 'Нет данных о сне',
        CorrelationType.activity => 'Нет данных об активности',
        CorrelationType.weather => 'Нет данных о погоде',
        CorrelationType.cycle => 'Нет данных о цикле',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _PeriodSelector(selected: _period, onChanged: _setPeriod),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<ScatterPoint>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  final points = snapshot.data ?? [];
                  if (points.isEmpty) {
                    return Center(
                      child: Text(
                        _emptyText,
                        style: const TextStyle(
                          fontFamily: 'DotGothic',
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Подсказка
                        if (widget.type == CorrelationType.cycle)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CycleLegend(),
                          ),
                        Expanded(
                          child: widget.type == CorrelationType.cycle
                              ? _CycleScatter(points: points)
                              : _Scatter(points: points, xLabel: _xLabel),
                        ),
                        const SizedBox(height: 16),
                        _AxisLabels(type: widget.type),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Period selector
// ──────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PBtn(
            label: 'Неделя',
            active: selected == _Period.week,
            onTap: () => onChanged(_Period.week)),
        const SizedBox(width: 8),
        _PBtn(
            label: 'Месяц',
            active: selected == _Period.month,
            onTap: () => onChanged(_Period.month)),
        const SizedBox(width: 8),
        _PBtn(
            label: 'Год',
            active: selected == _Period.year,
            onTap: () => onChanged(_Period.year)),
      ],
    );
  }
}

class _PBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          border: Border.all(
              color: active ? Colors.white : Colors.white30, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 12,
            color: active ? Colors.black : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Scatter (сон, активность, погода)
// ──────────────────────────────────────────────────

Color _pointColor(ScatterPoint p) =>
    moodColors[p.moodName] ?? const Color(0xFF888888);

FlGridData _grid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 0.5,
      getDrawingHorizontalLine: (v) => FlLine(
        color: v.abs() < 0.01 ? Colors.white24 : Colors.white12,
        strokeWidth: v.abs() < 0.01 ? 1.5 : 1,
      ),
    );

class _Scatter extends StatelessWidget {
  final List<ScatterPoint> points;
  final String xLabel;

  const _Scatter({required this.points, required this.xLabel});

  @override
  Widget build(BuildContext context) {
    final scatterSpots = points
        .map((p) => ScatterSpot(
              p.x,
              p.y.clamp(-1.0, 1.0),
              dotPainter: FlDotCirclePainter(
                radius: 5,
                color: _pointColor(p),
                strokeColor: Colors.transparent,
                strokeWidth: 0,
              ),
            ))
        .toList();

    final xs = points.map((p) => p.x);
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final pad = (maxX - minX).abs() < 0.01 ? 1.0 : (maxX - minX) * 0.12;

    return ScatterChart(
      ScatterChartData(
        minX: minX - pad,
        maxX: maxX + pad,
        minY: -1.15,
        maxY: 1.15,
        gridData: _grid(),
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
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) {
                  return const SizedBox.shrink();
                }
                final label =
                    val.abs() < 10 ? val.toStringAsFixed(1) : val.toInt().toString();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$label $xLabel',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontFamily: 'DotGothic',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        scatterSpots: scatterSpots,
        scatterTouchData: ScatterTouchData(enabled: false),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Cycle scatter (X=mood, Y=phase 0-3)
// ──────────────────────────────────────────────────

class _CycleScatter extends StatelessWidget {
  final List<ScatterPoint> points;

  const _CycleScatter({required this.points});

  @override
  Widget build(BuildContext context) {
    final scatterSpots = points.map((p) => ScatterSpot(
          p.x.clamp(-1.0, 1.0),
          p.y,
          dotPainter: FlDotCirclePainter(
            radius: 6,
            color: _pointColor(p),
            strokeColor: Colors.transparent,
            strokeWidth: 0,
          ),
        )).toList();

    return ScatterChart(
      ScatterChartData(
        minX: -1.15,
        maxX: 1.15,
        minY: -0.5,
        maxY: 3.5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.white12,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.5,
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    val.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontFamily: 'DotGothic'),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                const labels = ['М', 'Ф', 'О', 'Л'];
                const colors = [
                  Color(0xFFFF7979),
                  Color(0xFF66FF66),
                  Color(0xFFFFEB89),
                  Color(0xFFB8A1FF),
                ];
                final idx = val.round();
                if (idx < 0 || idx > 3 || val % 1 != 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  labels[idx],
                  style: TextStyle(
                    color: colors[idx],
                    fontSize: 12,
                    fontFamily: 'DotGothic',
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
        ),
        scatterSpots: scatterSpots,
        scatterTouchData: ScatterTouchData(enabled: false),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Cycle legend
// ──────────────────────────────────────────────────

class _CycleLegend extends StatelessWidget {
  static const _items = [
    (color: Color(0xFFFF7979), label: 'М — Менструальная'),
    (color: Color(0xFF66FF66), label: 'Ф — Фолликулярная'),
    (color: Color(0xFFFFEB89), label: 'О — Овуляция'),
    (color: Color(0xFFB8A1FF), label: 'Л — Лютеиновая'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: _items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: item.color),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontFamily: 'DotGothic',
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

// ──────────────────────────────────────────────────
// Axis labels
// ──────────────────────────────────────────────────

class _AxisLabels extends StatelessWidget {
  final CorrelationType type;
  const _AxisLabels({required this.type});

  @override
  Widget build(BuildContext context) {
    final (xLabel, yLabel) = switch (type) {
      CorrelationType.sleep => ('← меньше сна   больше сна →', 'Y: настроение (-1..1)'),
      CorrelationType.activity =>
        ('← меньше шагов   больше шагов →', 'Y: настроение (-1..1)'),
      CorrelationType.weather =>
        ('← холоднее   теплее →', 'Y: настроение (-1..1)'),
      CorrelationType.cycle =>
        ('X: настроение (-1..1)', 'Y: фаза цикла'),
    };

    return Column(
      children: [
        Text(
          xLabel,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 10,
            color: Colors.white24,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          yLabel,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 10,
            color: Colors.white24,
          ),
        ),
      ],
    );
  }
}
