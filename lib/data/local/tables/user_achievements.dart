import 'package:drift/drift.dart';

class UserAchievements extends Table {
  TextColumn get achievementId => text()();
  TextColumn get userId => text()();
  BoolColumn get isAchieved => boolean().withDefault(const Constant(false))();
  DateTimeColumn get achievedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId, achievementId};

}
