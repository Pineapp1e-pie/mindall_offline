import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/local/repositories/local_repository.dart';
import '../../domain/models/chart_models.dart';
import '../../domain/models/health_draft.dart';
import '../../domain/models/mood_entry_with_mood.dart';
import '../../domain/services/analytics_service.dart';
import '../assets/mood_colors.dart';
import '../models/mood_entry_ui_model.dart';
import 'correlation_screen.dart';
import 'mood_category_screen.dart';
import 'mood_entry_detail_screen.dart';

enum _Period { day, week, month }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Period _period = _Period.day;
  DateTime _selectedDay = DateTime.now();
  late AnalyticsService _service;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _service = AnalyticsService(context.read<LocalRepository>());
      _initialized = true;
    }
  }

  DateTimeRange get _range {
    final now = DateTime.now();
    return switch (_period) {
      _Period.day => DateTimeRange(
          start: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day),
          end: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59),
        ),
      _Period.week => DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        ),
      _Period.month => DateTimeRange(
          start: DateTime(now.year, now.month - 1, now.day),
          end: now,
        ),
    };
  }

  void _setPeriod(_Period p) => setState(() => _period = p);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDay = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  const Text(
                    'Дневник',
                    style: TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _PeriodSelector(selected: _period, onChanged: _setPeriod),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // ── Выбор даты (только в режиме День) ──
                  if (_period == _Period.day)
                    GestureDetector(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('d MMMM yyyy', 'ru').format(_selectedDay),
                              style: const TextStyle(
                                fontFamily: 'DotGothic',
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more,
                                color: Colors.white38, size: 16),
                          ],
                        ),
                      ),
                    ),

                  // ── График ──
                  _ChartSection(
                    period: _period,
                    selectedDay: _selectedDay,
                    range: _range,
                    service: _service,
                    repository: context.read<LocalRepository>(),
                  ),

                  // ── Записи (только День) ──
                  if (_period == _Period.day) ...[
                    const SizedBox(height: 24),
                    _EntriesSection(
                      day: _selectedDay,
                      repository: context.read<LocalRepository>(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Здоровье ──
                  _HealthSection(
                    day: _period == _Period.day ? _selectedDay : DateTime.now(),
                    repository: context.read<LocalRepository>(),
                  ),

                  const SizedBox(height: 24),

                  // ── Корреляции ──
                  const _SectionLabel('Корреляции'),
                  const SizedBox(height: 12),
                  _CorrelationCard(
                    title: 'Настроение : Сон (ч)',
                    onTap: () => _openCorrelation(CorrelationType.sleep),
                  ),
                  const SizedBox(height: 8),
                  _CorrelationCard(
                    title: 'Настроение : Активность',
                    onTap: () => _openCorrelation(CorrelationType.activity),
                  ),
                  const SizedBox(height: 8),
                  _CorrelationCard(
                    title: 'Настроение : Погода (°C)',
                    onTap: () => _openCorrelation(CorrelationType.weather),
                  ),
                  const SizedBox(height: 8),
                  _CorrelationCard(
                    title: 'Цикл : Настроение',
                    onTap: () => _openCorrelation(CorrelationType.cycle),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }

  void _openCorrelation(CorrelationType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CorrelationScreen(type: type),
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
        _PeriodBtn(
            label: 'День',
            active: selected == _Period.day,
            onTap: () => onChanged(_Period.day)),
        const SizedBox(width: 8),
        _PeriodBtn(
            label: 'Неделя',
            active: selected == _Period.week,
            onTap: () => onChanged(_Period.week)),
        const SizedBox(width: 8),
        _PeriodBtn(
            label: 'Месяц',
            active: selected == _Period.month,
            onTap: () => onChanged(_Period.month)),
      ],
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodBtn(
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
// Chart section
// ──────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final _Period period;
  final DateTime selectedDay;
  final DateTimeRange range;
  final AnalyticsService service;
  final LocalRepository repository;

  const _ChartSection({
    required this.period,
    required this.selectedDay,
    required this.range,
    required this.service,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (period == _Period.day) {
      return StreamBuilder<List<MoodEntryWithMood>>(
        stream: repository.watchMoodEntriesForDay(
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
        ),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) return const _EmptyChart(text: 'Нет записей');
          return _DayHourChart(entries: entries);
        },
      );
    }

    return FutureBuilder<List<TimePoint>>(
      future: service.getMoodTimeline(range.start, range.end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const _ChartPlaceholder();
        final points = snapshot.data!;
        if (points.isEmpty) return const _EmptyChart();
        return _MoodLineChart(points: points);
      },
    );
  }
}

// ──────────────────────────────────────────────────
// Entries section (День)
// ──────────────────────────────────────────────────

class _EntriesSection extends StatelessWidget {
  final DateTime day;
  final LocalRepository repository;

  const _EntriesSection({required this.day, required this.repository});

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime(day.year, day.month, day.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Настроение'),
        const SizedBox(height: 12),
        StreamBuilder<List<MoodEntryWithMood>>(
          stream: repository.watchMoodEntriesForDay(date),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Записей нет',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 13,
                    color: Colors.white24,
                  ),
                ),
              );
            }
            return Column(
              children: entries.map((e) {
                final time =
                    '${e.entry.createdAt.hour.toString().padLeft(2, '0')}:'
                    '${e.entry.createdAt.minute.toString().padLeft(2, '0')}';
                final color = moodColors[e.mood.name] ?? Colors.white;
                final uiModel = MoodEntryUiModel(
                  id: e.entry.id.toString(),
                  time: time,
                  color: color,
                  moodName: e.mood.name,
                  createdAt: e.entry.createdAt,
                );
                return _EntryRow(
                  time: time,
                  moodName: e.mood.name,
                  color: color,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MoodEntryDetailScreen(
                        entry: uiModel,
                        repository: repository,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final String time;
  final String moodName;
  final Color color;
  final VoidCallback onTap;

  const _EntryRow({
    required this.time,
    required this.moodName,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18221C),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          children: [
            Text(
              time,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 13,
                color: Colors.white, // эта строчка
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                moodName,
                style: TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Health section
// ──────────────────────────────────────────────────

class _HealthSection extends StatelessWidget {
  final DateTime day;
  final LocalRepository repository;

  const _HealthSection({required this.day, required this.repository});

  @override
  Widget build(BuildContext context) {
    final date = DateTime(day.year, day.month, day.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Здоровье'),
        const SizedBox(height: 12),
        FutureBuilder(
          future: repository.getHealthDataForDay(date),
          builder: (context, snapshot) {
            final h = snapshot.data;
            final sleepH =
                h?.sleepMinutes != null ? (h!.sleepMinutes! / 60).toStringAsFixed(1) : '—';
            final steps = h?.stepsAmount?.toString() ?? '—';
            final phase = h?.cyclePhase != null ? _phaseLabel(h!.cyclePhase!) : '—';

            return Row(
              children: [
                _HealthChip(icon: '🌙', label: 'Сон', value: '$sleepH ч'),
                const SizedBox(width: 8),
                _HealthChip(icon: '👟', label: 'Шаги', value: steps),
                const SizedBox(width: 8),
                _HealthChip(icon: '🔄', label: 'Цикл', value: phase),
              ],
            );
          },
        ),
      ],
    );
  }

  String _phaseLabel(CyclePhase phase) => switch (phase) {
        CyclePhase.menstruation => 'Менстр.',
        CyclePhase.follicular => 'Фолл.',
        CyclePhase.ovulation => 'Овуляция',
        CyclePhase.luteal => 'Лютеин.',
      };
}

class _HealthChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _HealthChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF18221C),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 9,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Correlation nav card
// ──────────────────────────────────────────────────

class _CorrelationCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _CorrelationCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF18221C),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Section label
// ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'DotGothic',
        fontSize: 14,
        color: Colors.white54,
        letterSpacing: 1,
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Chart widgets
// ──────────────────────────────────────────────────

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator(color: Colors.white70)),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String text;
  const _EmptyChart({this.text = 'Нет данных'});

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

Color _moodColor(double v) {
  if (v > 0.2) return const Color(0xFF66FF66);
  if (v < -0.2) return const Color(0xFFFF7979);
  return const Color(0xFFFFEB89);
}

FlGridData _grid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 0.5,
      getDrawingHorizontalLine: (v) => FlLine(
        color: v.abs() < 0.01 ? Colors.white24 : Colors.white12,
        strokeWidth: v.abs() < 0.01 ? 1.5 : 1,
      ),
    );

// График по часам для режима «День»
class _DayHourChart extends StatelessWidget {
  final List<MoodEntryWithMood> entries;
  const _DayHourChart({required this.entries});

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

    final hours = entries.map((e) => e.entry.createdAt.hour + e.entry.createdAt.minute / 60.0);
    final rawMin = hours.reduce((a, b) => a < b ? a : b);
    final rawMax = hours.reduce((a, b) => a > b ? a : b);
    // Округляем до кратного 4 с отступом
    final minX = ((rawMin / 4).floor() * 4).toDouble();
    final maxX = ((rawMax / 4).ceil() * 4).toDouble().clamp(minX + 4, 24.0);

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
          scatterTouchData: ScatterTouchData(enabled: false),
        ),
      ),
    );
  }
}

// График для режима «Неделя» / «Месяц» — линейный
class _MoodLineChart extends StatelessWidget {
  final List<TimePoint> points;
  const _MoodLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = points.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value.clamp(-1.0, 1.0)))
        .toList();
    final avg =
        points.map((p) => p.value).reduce((a, b) => a + b) / points.length;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: -1,
          maxY: 1,
          clipData: const FlClipData.all(),
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
                showTitles: points.length <= 12,
                interval: 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (val % 1 != 0 || idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final d = points[idx].time;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${d.day}.${d.month}',
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontFamily: 'DotGothic'),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: _moodColor(avg),
              barWidth: 2,
              dotData: FlDotData(
                show: points.length <= 14,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: _moodColor(spot.y),
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _moodColor(avg).withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Bottom nav (shared with HomeScreen style)
// ──────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: const Color(0xFF0E1511),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          _NavIcon(
            icon: Icons.add,
            isActive: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoodCategoryScreen()),
            ),
          ),
          _NavIcon(
            icon: Icons.bar_chart,
            isActive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _NavIcon(
      {required this.icon, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
