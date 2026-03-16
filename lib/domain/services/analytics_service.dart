import '../../data/local/repositories/local_repository.dart';
import '../models/chart_models.dart';

enum Period {
  day,
  week,
  month,
  year,
}

class AnalyticsService {
  final LocalRepository repository;

  AnalyticsService(this.repository);

  // ------------------------------
  // ГРАФИК НАСТРОЕНИЯ (динамика)
  // ------------------------------

  Future<List<TimePoint>> getMoodTimeline(
      DateTime from,
      DateTime to,
      ) async {
    final stats = await repository.getDailyMoodStats(from, to);

    return stats
        .map((s) => TimePoint(s.date, s.moodValue))
        .toList();
  }

  // ------------------------------
  // SCATTER: НАСТРОЕНИЕ ↔ СОН
  // ------------------------------

  Future<List<ScatterPoint>> getMoodVsSleep(
      DateTime from,
      DateTime to,
      ) async {
    final stats = await repository.getDailyMoodStats(from, to);

    final points = <ScatterPoint>[];

    for (final stat in stats) {
      final health =
      await repository.getHealthDataForDay(stat.date);

      if (health?.sleepMinutes == null) continue;

      final sleepHours =
          health!.sleepMinutes! / 60.0;

      points.add(
        ScatterPoint(
          sleepHours,
          stat.moodValue,
        ),
      );
    }

    return points;
  }

  // ------------------------------
  // SCATTER: НАСТРОЕНИЕ ↔ АКТИВНОСТЬ
  // ------------------------------

  Future<List<ScatterPoint>> getMoodVsActivity(
      DateTime from,
      DateTime to,
      ) async {
    final stats = await repository.getDailyMoodStats(from, to);

    final points = <ScatterPoint>[];

    for (final stat in stats) {
      final health =
      await repository.getHealthDataForDay(stat.date);

      if (health?.stepsAmount == null) continue;

      final steps = health!.stepsAmount!.toDouble();

      points.add(
        ScatterPoint(
          steps,
          stat.moodValue,
        ),
      );
    }

    return points;
  }
}