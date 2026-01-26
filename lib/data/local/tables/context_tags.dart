import 'package:drift/drift.dart';

enum ContextTagType {
  place,
  activity,
  social,
}

class ContextTags extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get type => textEnum<ContextTagType>()();
  // place | activity | social

  BoolColumn get isCustom =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

}
