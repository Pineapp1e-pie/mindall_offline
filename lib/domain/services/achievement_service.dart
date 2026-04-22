import '../models/achievement.dart';
import '../../data/local/repositories/local_repository.dart';
import '../../data/local/static/moods.dart';

class AchievementService {
  final LocalRepository _repository;

  AchievementService(this._repository);

  Future<int> calculateStreak(String userId) async {
    final dates = await _repository.getUniqueMoodEntryDates(userId);
    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    final mostRecent = dates.first;
    if (mostRecent != todayDate && mostRecent != yesterdayDate) return 0;

    int streak = 0;
    DateTime expected = mostRecent;
    for (final date in dates) {
      if (date == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<bool> hasAllMoodCategories(String userId) async {
    final count = await _repository.getDistinctMoodCategoryCount(userId);
    return count >= MoodCategory.values.length;
  }

  /// First-launch migration: inserts achievement rows if missing, then checks.
  /// Returns newly unlocked achievements so the UI can show popups.
  Future<List<Achievement>> initIfNeeded(String userId) async {
    final count = await _repository.countUserAchievements(userId);
    if (count > 0) return [];
    await _repository.initAchievementsForUser(userId);
    return checkAfterEntrySaved(userId);
  }

  /// Checks unachieved achievements after an entry is saved.
  /// Returns the list of newly unlocked achievements.
  Future<List<Achievement>> checkAfterEntrySaved(String userId) async {
    final unachieved = await _repository.getUnachievedAchievements(userId);
    if (unachieved.isEmpty) return [];

    final totalEntries = await _repository.countMoodEntries(userId);
    final streak = await calculateStreak(userId);
    final allMoods = await hasAllMoodCategories(userId);

    final now = DateTime.now();
    final newlyAchieved = <Achievement>[];

    for (final row in unachieved) {
      final catalog = kAchievements
          .where((a) => a.id == row.achievementId)
          .firstOrNull;
      if (catalog == null) continue;

      final unlocked = switch (catalog.conditionType) {
        'entry_count' => totalEntries >= catalog.conditionValue,
        'streak' => streak >= catalog.conditionValue,
        'all_moods' => allMoods,
        _ => false,
      };

      if (unlocked) {
        await _repository.markAchievementAchieved(
            userId, row.achievementId, now);
        newlyAchieved.add(catalog.copyWith(isAchieved: true, achievedAt: now));
      }
    }

    return newlyAchieved;
  }

}
