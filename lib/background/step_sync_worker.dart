import 'package:drift/drift.dart';
import 'package:health/health.dart';
import 'package:workmanager/workmanager.dart';

import '../data/local/app_database.dart';

const stepSyncTaskName = 'stepSync2330Task';

/// Точка входа для фонового воркера.
/// Должна быть top-level функцией (не метод класса).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == stepSyncTaskName) {
      await _syncSteps();
    }
    return true; // true = задача выполнена успешно
  });
}

Future<void> _syncSteps() async {
  try {
    final health = Health();

    // Запрашиваем разрешения (в фоне они уже должны быть выданы)
    final granted = await health.requestAuthorization(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );

    if (!granted) {
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

    // Открываем БД и обновляем запись здоровья за сегодня
    final db = AppDatabase();
    final existing = await (db.select(db.healthData)
          ..where((h) => h.date.equals(todayStart)))
        .getSingleOrNull();

    if (existing != null) {
      // Обновляем только шаги, сон и фазу цикла оставляем как есть
      await db.into(db.healthData).insertOnConflictUpdate(
            HealthDataCompanion.insert(
              date: todayStart,
              sleepMinutes: Value(existing.sleepMinutes),
              stepsAmount: Value(steps),
              cyclePhase: Value(existing.cyclePhase),
              source: const Value('auto'),
            ),
          );
      print('✅ [Worker] Запись обновлена: $steps шагов');
    } else {
      // Записи ещё нет — создаём новую только с шагами
      await db.into(db.healthData).insertOnConflictUpdate(
            HealthDataCompanion.insert(
              date: todayStart,
              stepsAmount: Value(steps),
              source: const Value('auto'),
            ),
          );
      print('✅ [Worker] Новая запись создана: $steps шагов');
    }

    await db.close();
  } catch (e) {
    print('❌ [Worker] Ошибка синхронизации шагов: $e');
  }
}