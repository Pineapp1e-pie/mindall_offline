import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'user_profile_service.dart';

enum SubscriptionFeature {
  moodEntry,
  basicAnalytics,
  notes,
  correlations,
  advancedAnalytics,
  weatherData,
  healthData,
  autoHealthData,
  detailedCharts,
  exportData,
  advancedRecommendations,
}

class SubscriptionAccessException implements Exception {
  final SubscriptionFeature feature;

  const SubscriptionAccessException(this.feature);

  @override
  String toString() => 'Эта функция доступна только в Premium';
}

class SubscriptionService extends ChangeNotifier {
  static const _pendingSyncKey = 'subscription_pending_sync';

  final UserProfileService _profileService;
  final SupabaseClient _client;

  bool _syncing = false;
  bool _pendingSync = false;

  SubscriptionService(this._profileService, {SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  SubscriptionType get type => _profileService.subscriptionType;
  bool get isPremium => type == SubscriptionType.premium;
  bool get isSyncing => _syncing;
  bool get hasPendingSync => _pendingSync;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingSync = prefs.getBool(_pendingSyncKey) ?? false;
    notifyListeners();

    if (_pendingSync) {
      await syncLocalToRemote();
    }
  }

  bool checkAccess(SubscriptionFeature feature) {
    return switch (feature) {
      SubscriptionFeature.moodEntry ||
      SubscriptionFeature.basicAnalytics ||
      SubscriptionFeature.notes => true,
      _ => isPremium,
    };
  }

  Future<void> ensureAccess(SubscriptionFeature feature) async {
    if (!checkAccess(feature)) {
      throw SubscriptionAccessException(feature);
    }
  }

  Future<void> toggleSubscription() async {
    final next = isPremium ? SubscriptionType.free : SubscriptionType.premium;
    await saveSubscription(next);
  }

  Future<void> saveSubscription(SubscriptionType type) async {
    await _saveLocal(type, pendingSync: true);
    await syncLocalToRemote();
  }

  Future<void> clearLocalState() async {
    await _setPendingSync(false);
    notifyListeners();
  }

  Future<void> syncFromRemote(User user) async {
    if (_pendingSync) {
      await syncLocalToRemote();
      return;
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('subscription_type')
          .eq('user_id', user.id)
          .maybeSingle();

      final remoteType = _parse(profile?['subscription_type'] as String?);
      await _saveLocal(remoteType, pendingSync: false);
    } catch (_) {
      // Offline-first: remote problems must not roll back local access state.
    }
  }

  Future<void> syncLocalToRemote() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _syncing = true;
    notifyListeners();

    try {
      await _client.from('profiles').upsert({
        'user_id': user.id,
        'subscription_type': type.name,
      });
      await _setPendingSync(false);
    } catch (_) {
      await _setPendingSync(true);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveLocal(
    SubscriptionType type, {
    required bool pendingSync,
  }) async {
    await _profileService.saveSubscriptionType(type);
    await _setPendingSync(pendingSync);
    notifyListeners();
  }

  Future<void> _setPendingSync(bool value) async {
    _pendingSync = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSyncKey, value);
  }

  SubscriptionType _parse(String? value) {
    return SubscriptionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SubscriptionType.free,
    );
  }
}
