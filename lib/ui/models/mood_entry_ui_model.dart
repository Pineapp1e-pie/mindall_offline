import 'dart:ui';

class MoodEntryUiModel {
  final String id;
  final String moodName;
  final String time;
  final Color color;

  MoodEntryUiModel( {
    required this.id,
    required this.time,
    required this.color,
    required this.moodName,
  });
}
