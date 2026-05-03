import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/local/repositories/local_repository.dart';
import '../../domain/models/chart_models.dart';
import '../../domain/services/analytics_service.dart';
import '../../domain/services/subscription_service.dart';
import '../assets/mood_colors.dart';
import '../widgets/paywall_widget.dart';

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
  DateTime _anchor = DateTime.now();
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
    final d = _anchor;
    return switch (_period) {
      _Period.week => () {
        final monday = d.subtract(Duration(days: d.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        final end = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return DateTimeRange(start: start, end: end);
      }(),
      _Period.month => DateTimeRange(
        start: DateTime(d.year, d.month, 1),
        end: DateTime(d.year, d.month + 1, 0, 23, 59, 59),
      ),
      _Period.year => DateTimeRange(
        start: DateTime(d.year, 1, 1),
        end: DateTime(d.year, 12, 31, 23, 59, 59),
      ),
    };
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return switch (_period) {
      _Period.week => _range.end.isBefore(now),
      _Period.month =>
        _anchor.year < now.year ||
            (_anchor.year == now.year && _anchor.month < now.month),
      _Period.year => _anchor.year < now.year,
    };
  }

  String get _rangeLabel {
    final d = _anchor;
    return switch (_period) {
      _Period.week => () {
        final monday = d.subtract(Duration(days: d.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final fmt = DateFormat('d MMM', 'ru');
        return '${fmt.format(monday)} – ${fmt.format(sunday)}';
      }(),
      _Period.month => DateFormat(
        'MMMM yyyy',
        'ru',
      ).format(DateTime(d.year, d.month)),
      _Period.year => '${d.year}',
    };
  }

  void _goPrev() => setState(() {
    _anchor = switch (_period) {
      _Period.week => _anchor.subtract(const Duration(days: 7)),
      _Period.month => DateTime(_anchor.year, _anchor.month - 1, 1),
      _Period.year => DateTime(_anchor.year - 1, 1, 1),
    };
    _future = _load();
  });

  void _goNext() {
    if (!_canGoNext) return;
    setState(() {
      _anchor = switch (_period) {
        _Period.week => _anchor.add(const Duration(days: 7)),
        _Period.month => DateTime(_anchor.year, _anchor.month + 1, 1),
        _Period.year => DateTime(_anchor.year + 1, 1, 1),
      };
      _future = _load();
    });
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
      _anchor = DateTime.now();
      _future = _load();
    });
  }

  String get _title => switch (widget.type) {
    CorrelationType.sleep => 'Настроение : Сон (ч)',
    CorrelationType.activity => 'Настроение : Активность',
    CorrelationType.weather => 'Настроение : Погода',
    CorrelationType.cycle => 'Цикл : Настроение',
  };

  String get _xLabel => switch (widget.type) {
    CorrelationType.sleep => 'ч',
    CorrelationType.activity => '',
    CorrelationType.weather => '°',
    CorrelationType.cycle => 'настроение',
  };

  String get _emptyText => switch (widget.type) {
    CorrelationType.sleep => 'Нет данных о сне',
    CorrelationType.activity => 'Нет данных об активности',
    CorrelationType.weather => 'Нет данных о погоде',
    CorrelationType.cycle => 'Нет данных о цикле',
  };

  void _showHelp(BuildContext context) {
    final (title, body) = switch (widget.type) {
      CorrelationType.sleep => (
        'Настроение и сон',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoText(
              'По горизонтали — часы сна за день, по вертикали — настроение от −1 (плохое) до +1 (хорошее).',
            ),
            const SizedBox(height: 12),
            _infoText(
              'Каждая точка — одна запись настроения в день с известными данными о сне. Цвет точки соответствует эмоции.',
            ),
            const SizedBox(height: 12),
            _infoText(
              'Если точки скапливаются правее и выше — больше сна связано с лучшим настроением. Если хаотично — связи нет.',
            ),
          ],
        ),
      ),
      CorrelationType.activity => (
        'Настроение и активность',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoText(
              'По горизонтали — количество шагов за день, по вертикали — настроение от −1 (плохое) до +1 (хорошее).',
            ),
            const SizedBox(height: 12),
            _infoText(
              'Каждая точка — одна запись настроения в день с известными данными о шагах. Цвет точки соответствует эмоции.',
            ),
            const SizedBox(height: 12),
            _infoText(
              'Если точки правее и выше — больше активности связано с лучшим настроением.',
            ),
          ],
        ),
      ),
      CorrelationType.weather => (
        'Настроение и погода',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoText(
              'По горизонтали — группа погоды, по вертикали — настроение от −1 (плохое) до +1 (хорошее).',
            ),
            const SizedBox(height: 12),
            _infoText('Группы:'),
            const SizedBox(height: 8),
            _dotRow(const Color(0xFF89CFF0), 'Очень холодно (≤ −25°)'),
            _dotRow(const Color(0xFF5B9BD5), 'Холодно (−25…−10°)'),
            _dotRow(const Color(0xFF7EC8E3), 'Прохладно (−10…+5°)'),
            _dotRow(const Color(0xFF66FF66), 'Комфортно (+5…+20°)'),
            _dotRow(const Color(0xFFFFDD3B), 'Тепло (+20…+30°)'),
            _dotRow(const Color(0xFFFF5959), 'Жарко (≥ +30°)'),
            const SizedBox(height: 12),
            _infoText(
              'Смотри в каком столбце точки выше — при такой погоде настроение обычно лучше.',
            ),
          ],
        ),
      ),
      CorrelationType.cycle => (
        'Цикл и настроение',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoText(
              'По горизонтали — настроение от −1 (плохое) до +1 (хорошее), по вертикали — фаза цикла.',
            ),
            const SizedBox(height: 12),
            _infoText('Фазы:'),
            const SizedBox(height: 8),
            _dotRow(const Color(0xFFFF7979), 'М — менструальная'),
            _dotRow(const Color(0xFF66FF66), 'Ф — фолликулярная'),
            _dotRow(const Color(0xFFFFEB89), 'О — овуляция'),
            _dotRow(const Color(0xFFB8A1FF), 'Л — лютеиновая'),
            const SizedBox(height: 12),
            _infoText(
              'Смотри в какой строке точки сдвинуты правее — в эту фазу настроение обычно лучше.',
            ),
          ],
        ),
      ),
    };
    _showInfoSheet(context, title: title, body: body);
  }

  void _showInfoSheet(
    BuildContext context, {
    required String title,
    required Widget body,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF18221C),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              body,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoText(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'DotGothic',
      fontSize: 13,
      color: Colors.white70,
      height: 1.6,
    ),
  );

  static Widget _dotRow(Color color, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3, right: 10),
          color: color,
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasAccess = context.watch<SubscriptionService>().checkAccess(
      SubscriptionFeature.correlations,
    );

    if (!hasAccess) {
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
            'Premium',
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 16,
              color: Colors.white,
            ),
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
        actions: [
          GestureDetector(
            onTap: () => _showHelp(context),
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        ],
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goPrev,
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _rangeLabel,
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _canGoNext ? _goNext : null,
                    child: Icon(
                      Icons.chevron_right,
                      color: _canGoNext ? Colors.white54 : Colors.white12,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                        if (widget.type == CorrelationType.cycle)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CycleLegend(),
                          ),
                        if (widget.type == CorrelationType.weather)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _WeatherLegend(),
                          ),
                        Expanded(
                          child: switch (widget.type) {
                            CorrelationType.cycle => _CycleScatter(
                              points: points,
                            ),
                            CorrelationType.weather => _WeatherScatter(
                              points: points,
                            ),
                            _ => _Scatter(points: points, xLabel: _xLabel),
                          },
                        ),
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
          onTap: () => onChanged(_Period.week),
        ),
        const SizedBox(width: 8),
        _PBtn(
          label: 'Месяц',
          active: selected == _Period.month,
          onTap: () => onChanged(_Period.month),
        ),
        const SizedBox(width: 8),
        _PBtn(
          label: 'Год',
          active: selected == _Period.year,
          onTap: () => onChanged(_Period.year),
        ),
      ],
    );
  }
}

class _PBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          border: Border.all(
            color: active ? Colors.white : Colors.white30,
            width: 1.5,
          ),
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

class _Scatter extends StatefulWidget {
  final List<ScatterPoint> points;
  final String xLabel;

  const _Scatter({required this.points, required this.xLabel});

  @override
  State<_Scatter> createState() => _ScatterState();
}

class _ScatterState extends State<_Scatter> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scatterSpots = widget.points
        .map(
          (p) => ScatterSpot(
            p.x,
            p.y.clamp(-1.0, 1.0),
            dotPainter: FlDotCirclePainter(
              radius: 5,
              color: _pointColor(p),
              strokeColor: Colors.transparent,
              strokeWidth: 0,
            ),
          ),
        )
        .toList();

    final xs = widget.points.map((p) => p.x);
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final pad = (maxX - minX).abs() < 0.01 ? 1.0 : (maxX - minX) * 0.12;
    final xLabel = widget.xLabel;

    return ScatterChart(
      ScatterChartData(
        minX: minX - pad,
        maxX: maxX + pad,
        minY: -1.15,
        maxY: 1.15,
        gridData: _grid(),
        borderData: FlBorderData(show: false),
        showingTooltipIndicators: _selectedIndex != null
            ? [_selectedIndex!]
            : [],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) {
                  return const SizedBox.shrink();
                }
                final num = val.abs() < 10
                    ? val.toStringAsFixed(1)
                    : val.toInt().toString();
                final label = xLabel.isEmpty ? num : '$num$xLabel';
                return Transform.rotate(
                  angle: -0.6,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'DotGothic',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        scatterSpots: scatterSpots,
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchSpotThreshold: 24,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1A2E),
            getTooltipItems: (spot) {
              final num = spot.x.abs() < 10
                  ? spot.x.toStringAsFixed(1)
                  : spot.x.toInt().toString();
              final xStr = xLabel.isEmpty ? num : '$num$xLabel';
              return ScatterTooltipItem(
                '$xStr\n${spot.y.toStringAsFixed(2)}',
                textStyle: const TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 11,
                  color: Colors.white,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            setState(() {
              _selectedIndex = response?.touchedSpot?.spotIndex;
            });
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Cycle scatter (X=mood, Y=phase 0-3)
// ──────────────────────────────────────────────────

class _CycleScatter extends StatefulWidget {
  final List<ScatterPoint> points;

  const _CycleScatter({required this.points});

  @override
  State<_CycleScatter> createState() => _CycleScatterState();
}

class _CycleScatterState extends State<_CycleScatter> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scatterSpots = widget.points
        .map(
          (p) => ScatterSpot(
            p.x.clamp(-1.0, 1.0),
            p.y,
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color: _pointColor(p),
              strokeColor: Colors.transparent,
              strokeWidth: 0,
            ),
          ),
        )
        .toList();

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
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.white12, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                      fontFamily: 'DotGothic',
                    ),
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
        showingTooltipIndicators: _selectedIndex != null
            ? [_selectedIndex!]
            : [],
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchSpotThreshold: 24,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1A2E),
            getTooltipItems: (spot) {
              const phases = ['М', 'Ф', 'О', 'Л'];
              final idx = spot.y.round().clamp(0, 3);
              return ScatterTooltipItem(
                '${spot.x.toStringAsFixed(2)}\n${phases[idx]}',
                textStyle: const TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 11,
                  color: Colors.white,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            setState(() {
              _selectedIndex = response?.touchedSpot?.spotIndex;
            });
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Weather scatter (X=mood, Y=category 0-5)
// ──────────────────────────────────────────────────

class _WeatherScatter extends StatefulWidget {
  final List<ScatterPoint> points;
  const _WeatherScatter({required this.points});

  @override
  State<_WeatherScatter> createState() => _WeatherScatterState();
}

class _WeatherScatterState extends State<_WeatherScatter> {
  int? _selectedIndex;

  static const _labels = ['ОХ', 'Хол', 'Пр', 'Ком', 'Теп', 'Жар'];
  static const _colors = [
    Color(0xFF89CFF0),
    Color(0xFF5B9BD5),
    Color(0xFF7EC8E3),
    Color(0xFF66FF66),
    Color(0xFFFFDD3B),
    Color(0xFFFF5959),
  ];

  @override
  Widget build(BuildContext context) {
    final scatterSpots = widget.points
        .map(
          (p) => ScatterSpot(
            p.x,
            p.y.clamp(-1.0, 1.0),
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color: _pointColor(p),
              strokeColor: Colors.transparent,
              strokeWidth: 0,
            ),
          ),
        )
        .toList();

    return ScatterChart(
      ScatterChartData(
        minX: -0.5,
        maxX: 5.5,
        minY: -1.15,
        maxY: 1.15,
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
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                final idx = val.round();
                if (idx < 0 || idx > 5 || (val - idx).abs() > 0.01) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _labels[idx],
                    style: TextStyle(
                      color: _colors[idx],
                      fontSize: 10,
                      fontFamily: 'DotGothic',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        scatterSpots: scatterSpots,
        showingTooltipIndicators: _selectedIndex != null
            ? [_selectedIndex!]
            : [],
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchSpotThreshold: 24,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1A2E),
            getTooltipItems: (spot) {
              final idx = spot.x.round().clamp(0, 5);
              return ScatterTooltipItem(
                '${_labels[idx]}\n${spot.y.toStringAsFixed(2)}',
                textStyle: const TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 11,
                  color: Colors.white,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            setState(() {
              _selectedIndex = response?.touchedSpot?.spotIndex;
            });
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Weather legend
// ──────────────────────────────────────────────────

class _WeatherLegend extends StatelessWidget {
  const _WeatherLegend();

  static const _items = [
    (color: Color(0xFF89CFF0), abbr: 'ОХ', rest: ' — очень холодно  (≤ −25°)'),
    (color: Color(0xFF5B9BD5), abbr: 'Хол', rest: ' — холодно  (−25…−10°)'),
    (color: Color(0xFF7EC8E3), abbr: 'Пр', rest: ' — прохладно  (−10…+5°)'),
    (color: Color(0xFF66FF66), abbr: 'Ком', rest: ' — комфортно  (+5…+20°)'),
    (color: Color(0xFFFFDD3B), abbr: 'Теп', rest: ' — тепло  (+20…+30°)'),
    (color: Color(0xFFFF5959), abbr: 'Жар', rest: ' — жарко  (≥ +30°)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18221C),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: item.abbr,
                        style: TextStyle(color: item.color),
                      ),
                      TextSpan(
                        text: item.rest,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
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
          .map(
            (item) => Row(
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
            ),
          )
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
      CorrelationType.sleep => (
        '← меньше сна   больше сна →',
        'Y: настроение (-1..1)',
      ),
      CorrelationType.activity => (
        '← меньше шагов   больше шагов →',
        'Y: настроение (-1..1)',
      ),
      CorrelationType.weather => (
        '← холоднее   теплее →',
        'Y: настроение (-1..1)',
      ),
      CorrelationType.cycle => ('X: настроение (-1..1)', 'Y: фаза цикла'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          xLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          yLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
