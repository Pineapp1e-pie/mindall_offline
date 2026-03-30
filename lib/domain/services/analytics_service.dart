import '../../data/local/repositories/local_repository.dart';
import '../../data/local/static/moods.dart';
import '../../data/local/tables/weather_data.dart';
import '../../domain/models/health_draft.dart';
import '../../domain/models/mood_entry_with_mood.dart';
import '../models/chart_models.dart';

class AnalyticsService {
  final LocalRepository repository;

  AnalyticsService(this.repository);

  // ------------------------------
  // TIMELINE: ср. настроение по дням
  // ------------------------------

  Future<List<TimePoint>> getMoodTimeline(
    DateTime from,
    DateTime to,
  ) async {
    final entries = await repository.getMoodEntriesWithMoodForPeriod(from, to);

    final Map<DateTime, List<double>> byDay = {};
    for (final e in entries) {
      final d = e.entry.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      byDay.putIfAbsent(day, () => []).add(e.mood.y);
    }

    final sorted = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return TimePoint(e.key, avg);
    }).toList();
  }

  // ------------------------------
  // SCATTER: день ↔ записи (для Экрана 16 «День»)
  // ------------------------------

  Future<List<TimePoint>> getDayEntries(DateTime day) async {
    final entries = await repository.getMoodEntriesForDay(day);
    return entries.map((e) {
      final h = e.entry.createdAt.hour + e.entry.createdAt.minute / 60.0;
      return TimePoint(
        DateTime(day.year, day.month, day.day, 0, 0).add(
          Duration(minutes: (h * 60).round()),
        ),
        e.mood.y,
      );
    }).toList();
  }

  // ------------------------------
  // SCATTER: настроение ↔ сон
  // Каждая точка = одна mood_entry, X = ч сна за тот день
  // ------------------------------

  Future<List<ScatterPoint>> getMoodVsSleep(
    DateTime from,
    DateTime to,
  ) async {
    final healthRecords = await repository.getHealthDataForPeriod(from, to);
    final points = <ScatterPoint>[];

    for (final h in healthRecords) {
      if (h.sleepMinutes == null) continue;
      final entries = await repository.getMoodEntriesForDay(h.date);
      for (final e in entries) {
        points.add(ScatterPoint(
          h.sleepMinutes! / 60.0,
          e.mood.y,
          moodName: e.mood.name,
        ));
      }
    }

    return points;
  }

  // ------------------------------
  // SCATTER: настроение ↔ шаги
  // Каждая точка = одна mood_entry, X = шаги за тот день
  // ------------------------------

  Future<List<ScatterPoint>> getMoodVsActivity(
    DateTime from,
    DateTime to,
  ) async {
    final healthRecords = await repository.getHealthDataForPeriod(from, to);
    final points = <ScatterPoint>[];

    for (final h in healthRecords) {
      if (h.stepsAmount == null) continue;
      final entries = await repository.getMoodEntriesForDay(h.date);
      for (final e in entries) {
        points.add(ScatterPoint(
          h.stepsAmount!.toDouble(),
          e.mood.y,
          moodName: e.mood.name,
        ));
      }
    }

    return points;
  }

  // ------------------------------
  // SCATTER: настроение ↔ температура (°C)
  // Каждая точка = одна mood_entry с погодой
  // ------------------------------

  Future<List<ScatterPoint>> getMoodVsWeather(
    DateTime from,
    DateTime to,
  ) async {
    final pairs = await repository.getMoodWeatherPairs(from, to);
    return pairs.map((p) {
      final temp = p.rawTemperature ?? _categoryMidpoint(p.temperatureCategory);
      return ScatterPoint(temp, p.moodY, moodName: p.moodName);
    }).toList();
  }

  double _categoryMidpoint(TemperatureCategory cat) => switch (cat) {
        TemperatureCategory.veryCold => -30.0,
        TemperatureCategory.cold => -17.0,
        TemperatureCategory.cool => -2.0,
        TemperatureCategory.comfortable => 12.0,
        TemperatureCategory.warm => 25.0,
        TemperatureCategory.hot => 35.0,
      };

  // ------------------------------
  // SCATTER: фаза цикла ↔ настроение
  // X = mood (-1..1), Y = phase index (0-3)
  // ------------------------------

  Future<List<ScatterPoint>> getMoodVsCycle(
    DateTime from,
    DateTime to,
  ) async {
    final healthRecords = await repository.getHealthDataForPeriod(from, to);
    final points = <ScatterPoint>[];

    for (final h in healthRecords) {
      if (h.cyclePhase == null) continue;
      final entries = await repository.getMoodEntriesForDay(h.date);
      for (final e in entries) {
        points.add(ScatterPoint(
          e.mood.y,
          _phaseIndex(h.cyclePhase!).toDouble(),
          moodName: e.mood.name,
        ));
      }
    }

    return points;
  }

  int _phaseIndex(CyclePhase phase) => switch (phase) {
        CyclePhase.menstruation => 0,
        CyclePhase.follicular => 1,
        CyclePhase.ovulation => 2,
        CyclePhase.luteal => 3,
      };

  // ------------------------------
  // КВАДРАНТЫ: количество записей по категориям за период
  // ------------------------------

  Future<Map<MoodCategory, int>> getQuadrantStats(
    DateTime from,
    DateTime to,
  ) async {
    final entries = await repository.getMoodEntriesWithMoodForPeriod(from, to);
    final counts = {
      MoodCategory.negativeActive: 0,
      MoodCategory.positiveActive: 0,
      MoodCategory.negativeCalm: 0,
      MoodCategory.positiveCalm: 0,
    };
    for (final e in entries) {
      counts[e.mood.category] = (counts[e.mood.category] ?? 0) + 1;
    }
    return counts;
  }

  // ------------------------------
  // ДЕНЬ-СТАТ: тип дня + среднее настроение (для недели/месяца)
  // ------------------------------

  Future<List<DayStats>> getDayStatsList(DateTime from, DateTime to) async {
    final entries = await repository.getMoodEntriesWithMoodForPeriod(from, to);

    final Map<DateTime, List<MoodEntryWithMood>> byDay = {};
    for (final e in entries) {
      final d = e.entry.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }

    final result = byDay.entries.map((entry) {
      final dayEntries = entry.value;
      final avgMood =
          dayEntries.map((e) => e.mood.y).reduce((a, b) => a + b) /
          dayEntries.length;
      return DayStats(entry.key, avgMood, _calcDayType(dayEntries));
    }).toList();

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  DayType _calcDayType(List<MoodEntryWithMood> entries) {
    if (entries.length <= 1) return DayType.stable;
    final cats = entries.map((e) => e.mood.category).toSet();
    if (cats.length == 1) return DayType.stable;
    final allPositive = cats.every(
      (c) =>
          c == MoodCategory.positiveActive || c == MoodCategory.positiveCalm,
    );
    final allNegative = cats.every(
      (c) =>
          c == MoodCategory.negativeActive || c == MoodCategory.negativeCalm,
    );
    if (allPositive || allNegative) return DayType.balanced;
    return DayType.contrast;
  }

  // ------------------------------
  // ГОД: квадранты по месяцам (для годового графика)
  // ------------------------------

  Future<List<MonthQuadrantData>> getYearQuadrantStats(int year) async {
    final entries = await repository.getMoodEntriesWithMoodForPeriod(
      DateTime(year, 1, 1),
      DateTime(year, 12, 31, 23, 59, 59),
    );

    final byMonth = List.generate(
      12,
      (_) => {
        MoodCategory.negativeActive: 0,
        MoodCategory.positiveActive: 0,
        MoodCategory.negativeCalm: 0,
        MoodCategory.positiveCalm: 0,
      },
    );

    for (final e in entries) {
      final m = e.entry.createdAt.month - 1;
      byMonth[m][e.mood.category] = (byMonth[m][e.mood.category] ?? 0) + 1;
    }

    return List.generate(12, (i) {
      final counts = byMonth[i];
      return MonthQuadrantData(
        DateTime(year, i + 1, 1),
        negativeActive: counts[MoodCategory.negativeActive]!,
        positiveActive: counts[MoodCategory.positiveActive]!,
        negativeCalm: counts[MoodCategory.negativeCalm]!,
        positiveCalm: counts[MoodCategory.positiveCalm]!,
      );
    });
  }
}
