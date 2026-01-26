import '../../../domain/models/mood_entry_with_mood.dart';
import '../app_database.dart';
import '../tables/health_data.dart';

abstract class LocalRepository {
  /// --- Mood entries ---
  Future<int> insertMoodEntry(MoodEntriesCompanion entry);

  Future<List<MoodEntryWithMood>> getMoodEntriesForDay(DateTime day);


  Future<List<MoodEntry>> getMoodEntriesForPeriod(
      DateTime from,
      DateTime to,
      );

  /// --- Daily stats ---
  Future<DailyMoodStat?> getDailyMoodStat(DateTime day);



  // Future<void> upsertDailyMoodStat(DailyMoodStatsCompanion stat);

  Future<List<DailyMoodStat>> getDailyMoodStats(
      DateTime from,
      DateTime to,
      );

  Future<void> upsertDailyMoodStat(DailyMoodStatsCompanion stat);

  /// --- Health data ---
  Future<HealthDataData?> getHealthDataForDay(DateTime day);

}
