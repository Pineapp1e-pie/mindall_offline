import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const _genderKey = 'user_gender';
  static const _lastPeriodKey = 'cycle_last_period';
  static const _cycleLengthKey = 'cycle_length';
  static const _periodDurationKey = 'cycle_period_duration';

  Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final genderStr = prefs.getString(_genderKey);
    if (genderStr == null) return null;

    final gender = Gender.values.firstWhere(
      (g) => g.name == genderStr,
      orElse: () => Gender.preferNotToSay,
    );

    final lastPeriodStr = prefs.getString(_lastPeriodKey);
    CycleSettings? cycleSettings;

    if (lastPeriodStr != null) {
      cycleSettings = CycleSettings(
        lastPeriodStart: DateTime.parse(lastPeriodStr),
        cycleLengthDays: prefs.getInt(_cycleLengthKey) ?? 28,
        periodDurationDays: prefs.getInt(_periodDurationKey) ?? 5,
      );
    }

    return UserProfile(gender: gender, cycleSettings: cycleSettings);
  }

  Future<void> saveGender(Gender gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender.name);
  }

  Future<void> saveCycleSettings(CycleSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastPeriodKey, settings.lastPeriodStart.toIso8601String());
    await prefs.setInt(_cycleLengthKey, settings.cycleLengthDays);
    await prefs.setInt(_periodDurationKey, settings.periodDurationDays);
  }
}
