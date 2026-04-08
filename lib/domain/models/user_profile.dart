enum Gender { female, male, preferNotToSay }

class CycleSettings {
  final DateTime lastPeriodStart;
  final int cycleLengthDays;
  final int periodDurationDays;

  const CycleSettings({
    required this.lastPeriodStart,
    this.cycleLengthDays = 28,
    this.periodDurationDays = 5,
  });
}

class UserProfile {
  final Gender gender;
  final String? username;
  final CycleSettings? cycleSettings;

  const UserProfile({
    required this.gender,
    this.username,
    this.cycleSettings,
  });

  bool get isFemale => gender == Gender.female;
}
