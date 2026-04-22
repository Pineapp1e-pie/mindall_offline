import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const _genderKey = 'user_gender';
  static const _usernameKey = 'user_username';
  static const _lastPeriodKey = 'cycle_last_period';
  static const _cycleLengthKey = 'cycle_length';
  static const _periodDurationKey = 'cycle_period_duration';
  static const _notifEnabledKey = 'notif_enabled';
  static const _notifHourKey = 'notif_hour';
  static const _notifMinuteKey = 'notif_minute';

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

    return UserProfile(
      gender: gender,
      username: prefs.getString(_usernameKey),
      cycleSettings: cycleSettings,
    );
  }

  Future<void> saveGender(Gender gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender.name);
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  Future<void> saveCycleSettings(CycleSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastPeriodKey, settings.lastPeriodStart.toIso8601String());
    await prefs.setInt(_cycleLengthKey, settings.cycleLengthDays);
    await prefs.setInt(_periodDurationKey, settings.periodDurationDays);
  }

  Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifEnabledKey) ?? false;
  }

  Future<int> loadNotificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifHourKey) ?? 18;
  }

  Future<int> loadNotificationMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifMinuteKey) ?? 0;
  }

  Future<void> saveNotificationSettings(
      bool enabled, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, enabled);
    await prefs.setInt(_notifHourKey, hour);
    await prefs.setInt(_notifMinuteKey, minute);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genderKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_lastPeriodKey);
    await prefs.remove(_cycleLengthKey);
    await prefs.remove(_periodDurationKey);
    await prefs.remove(_notifEnabledKey);
    await prefs.remove(_notifHourKey);
    await prefs.remove(_notifMinuteKey);
  }
}
