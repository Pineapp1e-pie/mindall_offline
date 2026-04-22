import '../app_database.dart';
import '../tables/context_tags.dart';

class ContextTagsInitializer {
  final AppDatabase db;

  ContextTagsInitializer(this.db);

  Future<void> init() async {
    final existing = await db.select(db.contextTags).get();
    if (existing.isNotEmpty) return;

    await db.batch((batch) {
      // ───── МЕСТО ─────
      batch.insertAll(db.contextTags, [
        ContextTagsCompanion.insert(
          name: 'Дом',
          type: ContextTagType.place,
        ),
        ContextTagsCompanion.insert(
          name: 'Работа',
          type: ContextTagType.place,
        ),
        ContextTagsCompanion.insert(
          name: 'Машина',
          type: ContextTagType.place,
        ),
      ]);

      // ───── ДЕЙСТВИЕ ─────
      batch.insertAll(db.contextTags, [
        ContextTagsCompanion.insert(
          name: 'Прогулка',
          type: ContextTagType.activity,
        ),
        ContextTagsCompanion.insert(
          name: 'Уборка',
          type: ContextTagType.activity,
        ),
        ContextTagsCompanion.insert(
          name: 'Разговор',
          type: ContextTagType.activity,
        ),
      ]);

      // ───── ОБЩЕСТВО ─────
      batch.insertAll(db.contextTags, [
        ContextTagsCompanion.insert(
          name: 'Одна/Один',//TODO пол
          type: ContextTagType.social,
        ),
        ContextTagsCompanion.insert(
          name: 'Семья',
          type: ContextTagType.social,
        ),
        ContextTagsCompanion.insert(
          name: 'Партнёр',
          type: ContextTagType.social,
        ),
      ]);
    });
  }
}
