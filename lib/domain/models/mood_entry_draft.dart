import 'package:mindall_offline/domain/models/weather_draft.dart';
import 'health_draft.dart';


class MoodEntryDraft {
  final int? editingEntryId;
  final DateTime? entryDate;

  final int moodId;

  final List<int> placeTagIds;
  final List<int> activityTagIds;
  final List<int> socialTagIds;

  final String note;
  final List<String> imagePaths;
  final String recordPath;

  final WeatherDraft? weather;

  final HealthDraft? health;

  MoodEntryDraft({
    this.editingEntryId,
    this.entryDate,
    required this.moodId,
    this.placeTagIds = const [],
    this.activityTagIds = const [],
    this.socialTagIds = const [],
    this.note = '',
    this.imagePaths = const [],
    this.recordPath = '',
    this.weather,
    this.health,
  });

  MoodEntryDraft copyWith({
    int? moodId,
    List<int>? placeTagIds,
    List<int>? activityTagIds,
    List<int>? socialTagIds,
    String? note,
    List<String>? imagePaths,
    String? recordPath,
    WeatherDraft? weather,
    final HealthDraft? health,
  }) {
    return MoodEntryDraft(
      editingEntryId: editingEntryId,
      entryDate: entryDate,
      moodId: moodId ?? this.moodId,
      placeTagIds: placeTagIds ?? this.placeTagIds,
      activityTagIds: activityTagIds ?? this.activityTagIds,
      socialTagIds: socialTagIds ?? this.socialTagIds,
      note: note ?? this.note,
      imagePaths: imagePaths ?? this.imagePaths,
      recordPath: recordPath ?? this.recordPath,
      weather: weather ?? this.weather,
      health: health ?? this.health,
    );
  }
}
