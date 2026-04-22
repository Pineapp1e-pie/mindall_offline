class Achievement {
  final String id;
  final String title;
  final String iconAsset;
  final String conditionType;
  final int conditionValue;
  final bool isAchieved;
  final DateTime? achievedAt;
  final bool synced;

  const Achievement({
    required this.id,
    required this.title,
    required this.iconAsset,
    required this.conditionType,
    required this.conditionValue,
    this.isAchieved = false,
    this.achievedAt,
    this.synced = false,
  });

  Achievement copyWith({
    bool? isAchieved,
    DateTime? achievedAt,
    bool? synced,
  }) =>
      Achievement(
        id: id,
        title: title,
        iconAsset: iconAsset,
        conditionType: conditionType,
        conditionValue: conditionValue,
        isAchieved: isAchieved ?? this.isAchieved,
        achievedAt: achievedAt ?? this.achievedAt,
        synced: synced ?? this.synced,
      );
}

const kAchievements = [
  Achievement(
    id: 'first_entry',
    title: 'Первый шаг',
    iconAsset: 'first_entry.svg',
    conditionType: 'entry_count',
    conditionValue: 1,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Неделя',
    iconAsset: 'week_entry.svg',
    conditionType: 'streak',
    conditionValue: 7,
  ),
  Achievement(
    id: 'streak_14',
    title: 'Две недели',
    iconAsset: '2weeks_entries.svg',
    conditionType: 'streak',
    conditionValue: 14,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Месяц',
    iconAsset: 'month_entries.svg',
    conditionType: 'streak',
    conditionValue: 30,
  ),
  Achievement(
    id: 'streak_100',
    title: '100 дней',
    iconAsset: '100_entries.svg',
    conditionType: 'streak',
    conditionValue: 100,
  ),
  Achievement(
    id: 'all_moods',
    title: 'Весь спектр',
    iconAsset: 'all_moods.svg',
    conditionType: 'all_moods',
    conditionValue: 1,
  ),
];
