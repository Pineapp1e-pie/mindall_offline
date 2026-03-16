// import 'package:health/health.dart';
//
// class HealthService {
//
//   final Health _health = Health();
//
//   Future<bool> requestPermissions() async {
//
//     final types = [
//       HealthDataType.SLEEP_ASLEEP,
//       HealthDataType.STEPS,
//     ];
//
//     final permissions = [
//       HealthDataAccess.READ,
//       HealthDataAccess.READ,
//     ];
//
//     return await _health.requestAuthorization(
//       types,
//       permissions: permissions,
//     );
//   }
//
//   Future<int?> getSleepMinutes() async {
//
//     final now = DateTime.now();
//     final start = DateTime(now.year, now.month, now.day);
//
//     final data = await _health.getHealthDataFromTypes(
//       types: [HealthDataType.SLEEP_ASLEEP],
//       startTime: start,
//       endTime: now,
//     );
//
//     if (data.isEmpty) return null;
//
//     double minutes = 0;
//
//     for (final item in data) {
//       minutes += item.value as double;
//     }
//
//     return minutes.round();
//   }
//
//   Future<int?> getStepsAmount() async {
//
//     final now = DateTime.now();
//     final start = DateTime(now.year, now.month, now.day);
//
//     final data = await _health.getHealthDataFromTypes(
//       types: [HealthDataType.STEPS],
//       startTime: start,
//       endTime: now,
//     );
//
//     if (data.isEmpty) return null;
//
//     double value = 0;
//
//     for (final item in data) {
//       value += item.value as double;
//     }
//
//     return value.round();
//   }
// }

import 'package:health/health.dart';
import 'package:flutter/services.dart';

class HealthService {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    print('🟡 HealthService: requestPermissions() started');

    try {
      // Типы данных для Android 15
      final types = [
        HealthDataType.STEPS,
        HealthDataType.SLEEP_ASLEEP,
      ];

      print('🟡 Requesting permissions for types: $types');

      // Для health 11.0.0 permissions передаются так
      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      // Убрали useHealthConnectIfAvailable - его нет в этой версии
      final result = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      print('✅ requestAuthorization result: $result');

      // result уже bool, не нужно преобразовывать
      return result;

    } on PlatformException catch (e) {
      print('❌ PlatformException: ${e.message}');
      print('   code: ${e.code}');
      print('   details: ${e.details}');

      // Специально для Android 15
      if (e.code == 'HEALTH_DATA_SERVICE_NOT_AVAILABLE') {
        print('❌ Health Connect не доступен. Проверьте настройки телефона.');
      }

      return false;
    } catch (e) {
      print('❌ Error: $e');
      return false;
    }
  }

  Future<int?> getStepAmount() async {
    print('🟡 HealthService: getStepAmount() started');

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);

      print('🟡 Fetching steps from $start to $now');

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: start,
        endTime: now,
      );

      print('✅ Received ${data.length} step entries');

      if (data.isEmpty) {
        print('ℹ️ No step data found');
        return null;
      }

      double totalSteps = 0;
      for (final item in data) {
        print('   - Step: ${item.value} at ${item.dateFrom}');
        totalSteps += item.value as double;
      }

      print('✅ Total steps: $totalSteps');
      return totalSteps.round();

    } catch (e) {
      print('❌ Error in getStepAmount: $e');
      return null;
    }
  }

  Future<int?> getSleepMinutes() async {
    print('🟡 HealthService: getSleepMinutes() started');

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

      print('🟡 Fetching sleep from $start to $now');

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: start,
        endTime: now,
      );

      print('✅ Received ${data.length} sleep entries');

      if (data.isEmpty) {
        print('ℹ️ No sleep data found');
        return null;
      }

      double totalMinutes = 0;
      for (final item in data) {
        print('   - Sleep: ${item.value} minutes');
        totalMinutes += item.value as double;
      }

      print('✅ Total sleep: $totalMinutes minutes');
      return totalMinutes.round();

    } catch (e) {
      print('❌ Error in getSleepMinutes: $e');
      return null;
    }
  }

  // Добавим метод для проверки доступности Health Connect
  Future<bool> isHealthConnectAvailable() async {
    try {
      // Пробуем запросить минимальные разрешения
      final result = await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      return result;
    } catch (e) {
      print('Error checking Health Connect: $e');
      return false;
    }
  }
}