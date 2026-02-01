import 'package:drift/drift.dart';

import 'mood_entries.dart';

enum TemperatureCategory {
  veryCold,   // ≤ -25
  cold,       // -25 … -10
  cool,       // -10 … +5
  comfortable,// +5 … +20
  warm,       // +20 … +30
  hot         // ≥ +30
}

enum PrecipitationType {
  none,
  rain,
  snow,
  fog
}

enum Cloudiness {
  sunny,      // ясно, солнце
  cloudy,     // облачно
  overcast    // пасмурно
}



class WeatherData extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get moodEntryId =>
      integer().references(MoodEntries, #id)();

  /// auto | manual
  TextColumn get source => text()();

  IntColumn get temperatureCategory =>
      intEnum<TemperatureCategory>()();

  /// числовая температура если api
  RealColumn get rawTemperature => real().nullable()();

  IntColumn get precipitation =>
      intEnum<PrecipitationType>().nullable()();

  IntColumn get cloudiness =>
      intEnum<Cloudiness>().nullable()();


}