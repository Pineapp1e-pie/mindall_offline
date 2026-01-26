import '../../data/local/app_database.dart';

class MoodEntryWithMood {
  final MoodEntry entry;
  final Mood mood;

  MoodEntryWithMood({
    required this.entry,
    required this.mood,
  });
}
