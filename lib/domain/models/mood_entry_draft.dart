import 'package:mindall/domain/models/weather_draft.dart';



class MoodEntryDraft {
  final int moodId;

  final List<int> placeTagIds;
  final List<int> activityTagIds;
  final List<int> socialTagIds;

  final String note;
  final List<String> imagePaths;
  final String recordPath;

  final WeatherDraft? weather;

  MoodEntryDraft({
    required this.moodId,
    this.placeTagIds = const [],
    this.activityTagIds = const [],
    this.socialTagIds = const [],
    this.note = '',
    this.imagePaths = const [],
    this.recordPath = '',
    this.weather,
  });

  MoodEntryDraft copyWith({
    List<int>? placeTagIds,
    List<int>? activityTagIds,
    List<int>? socialTagIds,
    String? note,
    List<String>? imagePaths,
    String? recordPath,
    WeatherDraft? weather,
  }) {
    return MoodEntryDraft(
      moodId: moodId,
      placeTagIds: placeTagIds ?? this.placeTagIds,
      activityTagIds: activityTagIds ?? this.activityTagIds,
      socialTagIds: socialTagIds ?? this.socialTagIds,
      note: note ?? this.note,
      imagePaths: imagePaths ?? this.imagePaths,
      recordPath: recordPath ?? this.recordPath,
      weather: weather ?? this.weather,
    );
  }
}
