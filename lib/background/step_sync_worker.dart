import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:health/health.dart';
import 'package:workmanager/workmanager.dart';

import '../data/local/app_database.dart';

const stepSyncTaskName = 'stepSync2330Task';

/// Точка входа для фонового воркера.
/// Должна быть top-level функцией (не метод класса).
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == stepSyncTaskName) {
      await _syncSteps();
      await _scheduleNextStepSync();
    }
    return true;
  });
}

Future<void> _scheduleNextStepSync() async {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 23, 30);
  final delay = tomorrow.difference(now);

  await Workmanager().registerOneOffTask(
    'stepSync_${tomorrow.year}_${tomorrow.month}_${tomorrow.day}',
    stepSyncTaskName,
    initialDelay: delay,
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

Future<void> _syncSteps() async {
  try {
    final health = Health();

    final hasPermission = await health.hasPermissions(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );
    if (hasPermission != true) {
      print('❌ [Worker] Нет разрешения на чтение шагов');
      return;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final data = await health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: todayStart,
      endTime: now,
    );

    if (data.isEmpty) {
      print('ℹ️ [Worker] Нет данных о шагах за сегодня');
      return;
    }

    double totalSteps = 0;
    for (final item in data) {
      totalSteps += (item.value as NumericHealthValue).numericValue.toDouble();
    }
    final steps = totalSteps.round();
    print('✅ [Worker] Шаги за сегодня: $steps');

    final db = AppDatabase();
    try {
      final existing = await (db.select(db.healthData)
            ..where((h) => h.date.equals(todayStart)))
          .getSingleOrNull();

      if (existing != null) {
        await db.into(db.healthData).insertOnConflictUpdate(
              HealthDataCompanion.insert(
                date: todayStart,
                sleepMinutes: Value(existing.sleepMinutes),
                stepsAmount: Value(steps),
                cyclePhase: Value(existing.cyclePhase),
                source: const Value('auto'),
              ),
            );
      } else {
        await db.into(db.healthData).insertOnConflictUpdate(
              HealthDataCompanion.insert(
                date: todayStart,
                stepsAmount: Value(steps),
                source: const Value('auto'),
              ),
            );
      }
      print('✅ [Worker] Запись обновлена: $steps шагов');
    } finally {
      await db.close();
    }
  } catch (e) {
    print('❌ [Worker] Ошибка синхронизации шагов: $e');
  }
}

/// Инициализирует WorkManager и планирует синхронизацию шагов.
Future<void> initWorkManager() async {
  await Workmanager().initialize(callbackDispatcher);
  scheduleStepSyncWorker();
}

/// Планирует синхронизацию шагов на 23:30 текущего или следующего дня.
void scheduleStepSyncWorker() {
  final now = DateTime.now();
  final target = DateTime(now.year, now.month, now.day, 23, 30);
  final delay = target.isAfter(now)
      ? target.difference(now)
      : target.add(const Duration(days: 1)).difference(now);

  Workmanager().registerOneOffTask(
    'stepSync_${now.year}_${now.month}_${now.day}',
    stepSyncTaskName,
    initialDelay: delay,
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
  print('✅ Синхронизация шагов запланирована через ${delay.inMinutes} мин');
}