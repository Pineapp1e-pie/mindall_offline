enum Gender { female, male, preferNotToSay }

enum SubscriptionType { free, premium }

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
  final SubscriptionType subscriptionType;

  const UserProfile({
    required this.gender,
    this.username,
    this.cycleSettings,
    this.subscriptionType = SubscriptionType.premium,
  });

  bool get isFemale => gender == Gender.female;
  bool get isPremium => subscriptionType == SubscriptionType.premium;
}
