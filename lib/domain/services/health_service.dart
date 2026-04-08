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
import '../models/health_draft.dart';

class HealthService {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    print('🟡 HealthService: requestPermissions() started');

    try {
      // Типы данных для Android 15
      final types = [
        HealthDataType.STEPS,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.MENSTRUATION_FLOW,
      ];

      print('🟡 Requesting permissions for types: $types');

      final permissions = [
        HealthDataAccess.READ,
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

  Future<int?> getStepAmount({DateTime? date}) async {
    print('🟡 HealthService: getStepAmount() started');

    try {
      final target = date ?? DateTime.now();
      final start = DateTime(target.year, target.month, target.day);
      final end = start.add(const Duration(days: 1));

      print('🟡 Fetching steps from $start to $end');

      // getTotalStepsInInterval агрегирует шаги с дедупликацией по источникам
      final steps = await _health.getTotalStepsInInterval(start, end);

      print('✅ Total steps: $steps');
      return steps;

    } catch (e) {
      print('❌ Error in getStepAmount: $e');
      return null;
    }
  }

  Future<int?> getSleepMinutes({DateTime? date}) async {
    print('🟡 HealthService: getSleepMinutes() started');

    try {
      final target = date ?? DateTime.now();
      final dayMidnight = DateTime(target.year, target.month, target.day);
      final start = dayMidnight.subtract(const Duration(days: 1));
      final end = dayMidnight.add(const Duration(days: 1));

      print('🟡 Fetching sleep from $start to $end');

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: start,
        endTime: end,
      );

      print('✅ Received ${data.length} sleep entries');

      if (data.isEmpty) {
        print('ℹ️ No sleep data found');
        return null;
      }

      // Берём только сессии, закончившиеся в нужный день
      final todaySessions = data.where((item) => item.dateTo.isAfter(dayMidnight)).toList();

      if (todaySessions.isEmpty) {
        print('ℹ️ No sleep data for today');
        return null;
      }

      double totalMinutes = 0;
      for (final item in todaySessions) {
        final minutes = item.dateTo.difference(item.dateFrom).inMinutes.toDouble();
        print('   - Sleep session: ${item.dateFrom} → ${item.dateTo} = $minutes min');
        totalMinutes += minutes;
      }

      print('✅ Total sleep: $totalMinutes minutes');
      return totalMinutes.round();

    } catch (e) {
      print('❌ Error in getSleepMinutes: $e');
      return null;
    }
  }

  Future<CyclePhase?> getCyclePhase() async {
    print('🟡 HealthService: getCyclePhase() started');

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.MENSTRUATION_FLOW],
        startTime: start,
        endTime: now,
      );

      print('✅ Received ${data.length} menstruation entries');

      if (data.isEmpty) {
        print('ℹ️ No menstruation data found');
        return null;
      }

      // Есть flow за последние 7 дней — фаза менструации
      return CyclePhase.menstruation;

    } catch (e) {
      print('❌ Error in getCyclePhase: $e');
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