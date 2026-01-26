import 'dart:math';
import 'package:drift/drift.dart';
import '../app_database.dart';

class FakeDataGenerator {
  final AppDatabase db;
  final Random _random = Random();

  FakeDataGenerator(this.db);

  Future<void> generateMoodEntries({
    int days = 14,
    int maxEntriesPerDay = 4,
  }) async {
    final moods = await db.select(db.moods).get();

    if (moods.isEmpty) {
      throw Exception('Moods table is empty. Seed moods first.');
    }

    for (int d = 0; d < days; d++) {
      final day = DateTime.now().subtract(Duration(days: d));

      final entriesCount = _random.nextInt(maxEntriesPerDay) + 1;

      for (int i = 0; i < entriesCount; i++) {
        final mood = moods[_random.nextInt(moods.length)];

        final entryTime = DateTime(
          day.year,
          day.month,
          day.day,
          _random.nextInt(24),
          _random.nextInt(60),
        );

        await db.into(db.moodEntries).insert(
          MoodEntriesCompanion.insert(
            userId: 'test_user', // ✅ ОБЯЗАТЕЛЬНО
            moodId: mood.id,
            createdAt: Value(entryTime), // ✅ Value(...)
          ),
        );
      }
    }
  }
}
