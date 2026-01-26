class MoodEntryDraft {
  final int moodId;

  final List<int> placeTagIds;
  final List<int> activityTagIds;
  final List<int> socialTagIds;

  MoodEntryDraft({
    required this.moodId,
    this.placeTagIds = const [],
    this.activityTagIds = const [],
    this.socialTagIds = const [],
  });

  MoodEntryDraft copyWith({
    List<int>? placeTagIds,
    List<int>? activityTagIds,
    List<int>? socialTagIds,
  }) {
    return MoodEntryDraft(
      moodId: moodId,
      placeTagIds: placeTagIds ?? this.placeTagIds,
      activityTagIds: activityTagIds ?? this.activityTagIds,
      socialTagIds: socialTagIds ?? this.socialTagIds,
    );
  }
}
