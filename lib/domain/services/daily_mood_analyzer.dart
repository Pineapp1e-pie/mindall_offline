import '../../data/local/app_database.dart';
import '../../data/local/repositories/local_repository.dart';
import '../../data/local/static/moods.dart';



class DailyMoodAnalyzer {
  final LocalRepository repository;

  DailyMoodAnalyzer(this.repository);

  Future<void> analyzeDay(DateTime day) async {
    final items =
    await repository.getMoodEntriesForDay(day);

    if (items.isEmpty) return;

    final avgX = _calculateAverage(
      items.map((e) => e.mood.x),
    );

    final avgY = _calculateAverage(
      items.map((e) => e.mood.y),
    );

    final dayType = _determineDayType(
      items.map((e) => e.mood.category).toList(),
    );

    final moodValue = avgY;

    await repository.upsertDailyMoodStat(
      DailyMoodStatsCompanion.insert(
        date: DateTime(day.year, day.month, day.day),
        avgX: avgX,
        avgY: avgY,
        moodValue: moodValue,
        dayType: dayType,
      ),
    );
  }

  double _calculateAverage(Iterable<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  String _determineDayType(List<MoodCategory> categories) {
    final unique = categories.toSet();

    if (unique.length == 1) {
      return 'stable_${unique.first.name}';
    }

    final hasPositive = unique.any(
          (c) => c == MoodCategory.positiveActive ||
          c == MoodCategory.positiveCalm,
    );

    final hasNegative = unique.any(
          (c) => c == MoodCategory.negativeActive ||
          c == MoodCategory.negativeCalm,
    );

    if (hasPositive && hasNegative) {
      return 'contrast';
    }

    return hasPositive ? 'positive' : 'negative';
  }
}
