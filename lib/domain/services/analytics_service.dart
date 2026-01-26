import '../../data/local/tables/health_data.dart';
import '../models/chart_models.dart';
import '../../data/local/repositories/local_repository.dart';
import '../../data/local/app_database.dart';

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
      final health = await repository.getHealthDataForDay(stat.date);
      if (health?.sleepHours == null) continue;

      points.add(
        ScatterPoint(
          health!.sleepHours!,
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
      final health = await repository.getHealthDataForDay(stat.date);
      if (health?.activityLevel == null) continue;

      final activityValue = _mapActivityToNumber(
        health!.activityLevel!,
      );

      points.add(
        ScatterPoint(
          activityValue,
          stat.moodValue,
        ),
      );
    }

    return points;
  }

  // ------------------------------
  // helpers
  // ------------------------------

  double _mapActivityToNumber(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.low:
        return 0;
      case ActivityLevel.medium:
        return 1;
      case ActivityLevel.high:
        return 2;
    }
  }
}
