import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserProfileService extends ChangeNotifier {
  static const _genderKey = 'user_gender';
  static const _usernameKey = 'user_username';
  static const _lastPeriodKey = 'cycle_last_period';
  static const _cycleLengthKey = 'cycle_length';
  static const _periodDurationKey = 'cycle_period_duration';
  static const _notifEnabledKey = 'notif_enabled';
  static const _notifHourKey = 'notif_hour';
  static const _notifMinuteKey = 'notif_minute';
  static const _subscriptionTypeKey = 'subscription_type';

  Gender? _gender;
  CycleSettings? _cycleSettings;
  String? _username;
  SubscriptionType _subscriptionType = SubscriptionType.free;

  Gender? get gender => _gender;
  CycleSettings? get cycleSettings => _cycleSettings;
  String? get username => _username;
  SubscriptionType get subscriptionType => _subscriptionType;
  bool get isFemale => _gender == Gender.female;
  bool get trackCycle => _cycleSettings != null;
  bool get isPremium => _subscriptionType == SubscriptionType.premium;

  /// Загружает данные из SharedPreferences в память. Вызывать один раз при запуске.
  Future<void> init() async {
    final profile = await load();
    if (profile != null) {
      _gender = profile.gender;
      _cycleSettings = profile.cycleSettings;
      _username = profile.username;
      _subscriptionType = profile.subscriptionType;
    }
  }

  Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final genderStr = prefs.getString(_genderKey);
    final subscriptionType = _parseSubscriptionType(
      prefs.getString(_subscriptionTypeKey),
    );
    if (genderStr == null) {
      _subscriptionType = subscriptionType;
      return null;
    }

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
      subscriptionType: subscriptionType,
    );
  }

  SubscriptionType _parseSubscriptionType(String? value) {
    return SubscriptionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SubscriptionType.free,
    );
  }

  Future<void> saveGender(Gender gender) async {
    _gender = gender;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender.name);
  }

  Future<void> saveUsername(String username) async {
    _username = username;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  Future<void> saveCycleSettings(CycleSettings settings) async {
    _cycleSettings = settings;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastPeriodKey,
      settings.lastPeriodStart.toIso8601String(),
    );
    await prefs.setInt(_cycleLengthKey, settings.cycleLengthDays);
    await prefs.setInt(_periodDurationKey, settings.periodDurationDays);
  }

  Future<void> saveSubscriptionType(SubscriptionType type) async {
    _subscriptionType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionTypeKey, type.name);
  }

  Future<void> clearCycleSettings() async {
    _cycleSettings = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPeriodKey);
    await prefs.remove(_cycleLengthKey);
    await prefs.remove(_periodDurationKey);
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
    bool enabled,
    int hour,
    int minute,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, enabled);
    await prefs.setInt(_notifHourKey, hour);
    await prefs.setInt(_notifMinuteKey, minute);
  }

  Future<void> clearAll() async {
    _gender = null;
    _cycleSettings = null;
    _username = null;
    _subscriptionType = SubscriptionType.free;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genderKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_lastPeriodKey);
    await prefs.remove(_cycleLengthKey);
    await prefs.remove(_periodDurationKey);
    await prefs.remove(_notifEnabledKey);
    await prefs.remove(_notifHourKey);
    await prefs.remove(_notifMinuteKey);
    await prefs.remove(_subscriptionTypeKey);
  }

  // user_profile_service.dart
  Future<void> syncFromSupabase(String userId) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      final genderStr = response['gender'] as String?;
      final username = response['username'] as String?;
      final subscriptionStr = response['subscription_type'] as String?;

      if (genderStr != null) {
        final gender = Gender.values.firstWhere(
              (g) => g.name == genderStr,
          orElse: () => Gender.preferNotToSay,
        );
        await saveGender(gender);
      }
      if (username != null) {
        await saveUsername(username);
      }
      if (subscriptionStr != null) {
        final subType = SubscriptionType.values.firstWhere(
              (t) => t.name == subscriptionStr,
          orElse: () => SubscriptionType.free,
        );
        await saveSubscriptionType(subType);
      }
    }
  }
}
