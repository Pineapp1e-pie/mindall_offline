import '../app_database.dart';
import 'moods_seed.dart';

class MoodsInitializer {
  final AppDatabase db;

  MoodsInitializer(this.db);

  Future<void> init() async {
    final count = await db.select(db.moods).get();

    if (count.isNotEmpty) return; // уже есть

    for (final mood in moodsSeed) {
      await db.into(db.moods).insert(
        MoodsCompanion.insert(
          name: mood.name,
          x: mood.x,
          y: mood.y,
          category: mood.category,
        ),
      );
    }
  }
}
