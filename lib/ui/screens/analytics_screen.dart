import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/local/repositories/local_repository.dart';
import '../../domain/models/chart_models.dart';
import '../../domain/models/mood_entry_with_mood.dart';
import '../../domain/services/analytics_service.dart';
import '../assets/mood_colors.dart';
import '../models/mood_entry_ui_model.dart';
import '../widgets/analytics/chart_shared.dart';
import '../widgets/analytics/week_chart.dart';
import '../widgets/analytics/month_calendar.dart';
import '../widgets/analytics/year_bars_chart.dart';
import 'correlation_screen.dart';
import 'mood_category_screen.dart';
import 'mood_entry_detail_screen.dart';

enum _Period { day, week, month, year }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Period _period = _Period.day;
  DateTime _selectedDay = DateTime.now();
  DateTime? _chartSelectedDay;
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
    final d = _selectedDay;
    return switch (_period) {
      _Period.day => DateTimeRange(
          start: DateTime(d.year, d.month, d.day),
          end: DateTime(d.year, d.month, d.day, 23, 59, 59),
        ),
      _Period.week => () {
          final monday = d.subtract(Duration(days: d.weekday - 1));
          final start = DateTime(monday.year, monday.month, monday.day);
          final end = start
              .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
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

  String get _rangeLabel {
    final d = _selectedDay;
    switch (_period) {
      case _Period.day:
        return DateFormat('d MMMM yyyy', 'ru').format(d);
      case _Period.week:
        final monday = d.subtract(Duration(days: d.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final fmt = DateFormat('d MMM', 'ru');
        return '${fmt.format(monday)} – ${fmt.format(sunday)}';
      case _Period.month:
        return DateFormat('MMMM yyyy', 'ru').format(DateTime(d.year, d.month));
      case _Period.year:
        return '${d.year}';
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      _Period.day => _selectedDay.isBefore(today),
      _Period.week => _range.end.isBefore(now),
      _Period.month =>
        _selectedDay.year < now.year ||
            (_selectedDay.year == now.year &&
                _selectedDay.month < now.month),
      _Period.year => _selectedDay.year < now.year,
    };
  }

  void _goPrev() {
    setState(() {
      _chartSelectedDay = null;
      _selectedDay = switch (_period) {
        _Period.day => _selectedDay.subtract(const Duration(days: 1)),
        _Period.week => _selectedDay.subtract(const Duration(days: 7)),
        _Period.month =>
          DateTime(_selectedDay.year, _selectedDay.month - 1, 1),
        _Period.year => DateTime(_selectedDay.year - 1, 1, 1),
      };
    });
  }

  void _goNext() {
    if (!_canGoNext) return;
    setState(() {
      _chartSelectedDay = null;
      _selectedDay = switch (_period) {
        _Period.day => _selectedDay.add(const Duration(days: 1)),
        _Period.week => _selectedDay.add(const Duration(days: 7)),
        _Period.month =>
          DateTime(_selectedDay.year, _selectedDay.month + 1, 1),
        _Period.year => DateTime(_selectedDay.year + 1, 1, 1),
      };
    });
  }

  void _setPeriod(_Period p) => setState(() {
        _period = p;
        _chartSelectedDay = null;
      });

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

  void _showChartHelp(BuildContext context) {
    final (title, body) = switch (_period) {
      _Period.day => (
          'График за день',
          _buildDayHelp(),
        ),
      _Period.week => (
          'График за неделю',
          _buildWeekMonthHelp(isMonth: false),
        ),
      _Period.month => (
          'График за месяц',
          _buildWeekMonthHelp(isMonth: true),
        ),
      _Period.year => (
          'График за год',
          _buildYearHelp(),
        ),
    };
    _showInfoSheet(context, title: title, body: body);
  }

  Widget _buildDayHelp() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoText('По горизонтали — время суток, по вертикали — настроение от −1 (плохое) до +1 (хорошее). Каждая точка — одна запись.'),
          const SizedBox(height: 16),
          _infoText('Цвет точки:'),
          const SizedBox(height: 10),
          _dotRow(const Color(0xFF46FF46), 'спокойное позитивное — покой, гармония, комфорт и тд'),
          _dotRow(const Color(0xFFFFDD3B), 'активное позитивное — радость, восторг, энтузиазм и тд'),
          _dotRow(const Color(0xFF835AFF), 'спокойное негативное — грусть, апатия, одиночество и тд'),
          _dotRow(const Color(0xFFFF5959), 'активное негативное — злость, тревога, раздражение и тд'),
        ],
      );

  Widget _buildWeekMonthHelp({required bool isMonth}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoText(isMonth
              ? 'Каждая клетка — один день. Нажми на день, чтобы посмотреть записи.'
              : 'Каждая точка — среднее настроение за день от −1 (плохой день) до +1 (хороший день). Нажми на точку, чтобы посмотреть записи дня.'),
          const SizedBox(height: 16),
          _infoText('Цвет показывает насколько разным было настроение в течение дня:'),
          const SizedBox(height: 10),
          _dotRow(const Color(0xFF7EC8E3), 'стабильный — эмоции примерно одинаковые'),
          _dotRow(const Color(0xFFB8A9E3), 'сбалансированный — разные, но в одном направлении'),
          _dotRow(const Color(0xFFF4A261), 'контрастный — настроение сильно менялось в течение дня'),
        ],
      );

  Widget _buildYearHelp() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoText('Каждый столбец — один месяц. Высота — общее количество записей. Цвета показывают из каких эмоций состоял месяц:'),
          const SizedBox(height: 10),
          _dotRow(const Color(0xFF46FF46), 'спокойное позитивное — покой, гармония, комфорт и тд'),
          _dotRow(const Color(0xFFFFDD3B), 'активное позитивное — радость, восторг, энтузиазм и тд'),
          _dotRow(const Color(0xFF835AFF), 'спокойное негативное — грусть, апатия, одиночество и тд'),
          _dotRow(const Color(0xFFFF5959), 'активное негативное — злость, тревога, раздражение и тд'),
        ],
      );


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

  void _showInfoSheet(BuildContext context,
      {required String title, required Widget body}) {
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
                  // ── Навигатор периода ──
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _goPrev,
                          child: const Icon(Icons.chevron_left,
                              color: Colors.white54, size: 20),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _period == _Period.day ? _pickDate : null,
                          child: Text(
                            _rangeLabel,
                            style: TextStyle(
                              fontFamily: 'DotGothic',
                              fontSize: 13,
                              color: _period == _Period.day
                                  ? Colors.white70
                                  : Colors.white54,
                            ),
                          ),
                        ),
                        if (_period == _Period.day) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.expand_more,
                              color: Colors.white38, size: 14),
                        ],
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _canGoNext ? _goNext : null,
                          child: Icon(Icons.chevron_right,
                              color: _canGoNext
                                  ? Colors.white54
                                  : Colors.white12,
                              size: 20),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showChartHelp(context),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white30, width: 1),
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
                  ),

                  // ── График ──
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -200) _goNext();
                      if (v > 200) _goPrev();
                    },
                    child: _ChartSection(
                      period: _period,
                      selectedDay: _selectedDay,
                      range: _range,
                      service: _service,
                      repository: context.read<LocalRepository>(),
                      onDaySelected: (day) =>
                          setState(() => _chartSelectedDay = day),
                    ),
                  ),


                  // ── Записи ──
                  if (_period == _Period.day) ...[
                    const SizedBox(height: 24),
                    _EntriesSection(
                      day: _selectedDay,
                      repository: context.read<LocalRepository>(),
                    ),
                  ] else if (_chartSelectedDay != null &&
                      (_period == _Period.week ||
                          _period == _Period.month)) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(
                      DateFormat('d MMMM', 'ru').format(_chartSelectedDay!),
                    ),
                    const SizedBox(height: 12),
                    _EntriesSection(
                      day: _chartSelectedDay!,
                      repository: context.read<LocalRepository>(),
                    ),
                  ],




                  const SizedBox(height: 24),

                  // ── Корреляции ──
                  const _SectionLabel('Корреляции'),
                  const SizedBox(height: 12),
                  _CorrelationCard(
                    title: 'Настроение : Сон',
                    onTap: () => _openCorrelation(CorrelationType.sleep),
                  ),
                  const SizedBox(height: 8),
                  _CorrelationCard(
                    title: 'Настроение : Шаги',
                    onTap: () => _openCorrelation(CorrelationType.activity),
                  ),
                  const SizedBox(height: 8),
                  _CorrelationCard(
                    title: 'Настроение : Погода',
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
          const SizedBox(width: 8),
          _PeriodBtn(
              label: 'Год',
              active: selected == _Period.year,
              onTap: () => onChanged(_Period.year)),
        ],
      ),
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
            color: active ? Colors.black : Colors.white70,
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
  final void Function(DateTime)? onDaySelected;

  const _ChartSection({
    required this.period,
    required this.selectedDay,
    required this.range,
    required this.service,
    required this.repository,
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return switch (period) {
      _Period.day => StreamBuilder<List<MoodEntryWithMood>>(
          stream: repository.watchMoodEntriesForDay(
            DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
          ),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) return const EmptyChart(text: 'Нет записей');
            return DayHourChart(entries: entries);
          },
        ),
      _Period.week => FutureBuilder<List<DayStats>>(
          future: service.getDayStatsList(range.start, range.end),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const ChartPlaceholder();
            return WeekChart(
              dayStats: snapshot.data!,
              weekStart: range.start,
              onDayTap: onDaySelected,
            );
          },
        ),
      _Period.month => FutureBuilder<List<DayStats>>(
          future: service.getDayStatsList(range.start, range.end),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const ChartPlaceholder();
            return MonthCalendar(
              dayStats: snapshot.data!,
              month: range.start,
              onDayTap: onDaySelected,
            );
          },
        ),
      _Period.year => FutureBuilder<List<MonthQuadrantData>>(
          future: service.getYearQuadrantStats(selectedDay.year),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const ChartPlaceholder();
            return YearBarsChart(data: snapshot.data!);
          },
        ),
    };
  }
}

// ──────────────────────────────────────────────────
// Entries section
// ──────────────────────────────────────────────────

class _EntriesSection extends StatelessWidget {
  final DateTime day;
  final LocalRepository repository;

  const _EntriesSection({required this.day, required this.repository});

  @override
  Widget build(BuildContext context) {
    final date = DateTime(day.year, day.month, day.day);

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
                color: Colors.white,
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
        fontSize: 18,
        color: Colors.white70,
        letterSpacing: 1,
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Bottom nav
// ──────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(top: 24, bottom: 24 + bottomInset),
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
