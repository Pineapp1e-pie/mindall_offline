import 'package:drift/drift.dart';

import '../../../domain/models/health_draft.dart';



class HealthData extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get date => dateTime().unique()();

  IntColumn get sleepMinutes => integer().nullable()();

  IntColumn get stepsAmount => integer().nullable()();

  TextColumn get cyclePhase =>
      textEnum<CyclePhase>().nullable()();

  TextColumn get source => text().nullable()();
}
