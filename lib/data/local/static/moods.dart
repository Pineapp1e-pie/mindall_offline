import 'package:drift/drift.dart';

enum MoodCategory {

  negativeActive,
  positiveActive,

  negativeCalm,
  positiveCalm,
}


class Moods extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()(); // "Тревога", "Радость" и т.д.

  RealColumn get x => real()(); // -0.33
  RealColumn get y => real()(); // 0.66

  TextColumn get category => textEnum<MoodCategory>()();
}
