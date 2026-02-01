import 'package:drift/drift.dart';
import '../app_database.dart';
import '../mappers/weather_mapper.dart';
import '../repositories/weather_repository.dart';
import '../tables/weather_data.dart';

WeatherDataCompanion weatherFromApi({
  required int moodEntryId,
  required WeatherApiResult api,
}) {
  return WeatherDataCompanion.insert(
    moodEntryId: moodEntryId,
    source: 'auto',
    temperatureCategory: mapTemperature(api.temperature),
    rawTemperature: Value(api.temperature),
    precipitation: Value(mapPrecipitation(api.condition)),
    cloudiness: Value(mapCloudiness(api.clouds)),
  );
}
