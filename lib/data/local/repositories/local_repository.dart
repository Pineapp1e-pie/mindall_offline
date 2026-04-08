import '../../../domain/models/mood_entry_with_mood.dart';
import '../app_database.dart';
import '../tables/context_details.dart';
import '../tables/health_data.dart';
import '../../../domain/models/mood_entry_draft.dart';
import '../tables/weather_data.dart';

class MoodWeatherRecord {
  final double moodX;
  final String moodName;
  final TemperatureCategory temperatureCategory;
  final double? rawTemperature;

  const MoodWeatherRecord({
    required this.moodX,
    required this.moodName,
    required this.temperatureCategory,
    this.rawTemperature,
  });
}

abstract class LocalRepository {
  /// --- Mood entries ---
  Future<int> insertMoodEntry(MoodEntriesCompanion entry);

  Future<List<MoodEntryWithMood>> getMoodEntriesForDay(DateTime day);

  Stream<List<MoodEntryWithMood>> watchMoodEntriesForDay(DateTime day);

  Future<void> saveFullEntry(MoodEntryDraft draft);

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
  Future<void> insertHealthData(HealthDataCompanion data); // ← новый метод
  Future<HealthDataData?> getHealthDataForDay(DateTime day);

  Future<void> insertContextDetails(ContextDetailsCompanion data);



// Замени типы на правильные из Drift
  Future<ContextDetail?> getContextDetailsForEntry(int entryId);
  Future<WeatherDataData?> getWeatherForEntry(int entryId);
  Future<List<ContextTag>> getTagsForEntry(int entryId);

  Future<List<MoodWeatherRecord>> getMoodWeatherPairs(DateTime from, DateTime to);

  Future<List<HealthDataData>> getHealthDataForPeriod(DateTime from, DateTime to);

  Future<List<MoodEntryWithMood>> getMoodEntriesWithMoodForPeriod(DateTime from, DateTime to);

  Future<void> deleteMoodEntry(int entryId);

  Future<void> updateNote(int entryId, String? note);

  Future<MoodEntryDraft> getMoodEntryAsDraft(int entryId);

  Future<void> updateFullEntry(int entryId, MoodEntryDraft draft);

  Future<void> clearUserData();
}


