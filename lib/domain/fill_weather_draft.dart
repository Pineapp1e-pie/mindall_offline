
import '../data/local/mappers/weather_mapper.dart';
import '../data/local/repositories/weather_repository.dart';
import 'models/mood_entry_draft.dart';
import 'models/weather_draft.dart';

Future<MoodEntryDraft> fillWeatherDraft({
  required MoodEntryDraft draft,
  required WeatherRepository repository,
  required double lat,
  required double lon,
}) async {
  final api = await repository.fetchWeather(
    lat: lat,
    lon: lon,
  );

  final weatherDraft = WeatherDraft(
    cloudiness: mapCloudiness(api.clouds),
    temperature: mapTemperature(api.temperature),
    precipitation: mapPrecipitation(api.condition),
    source: 'auto',
  );

  return draft.copyWith(weather: weatherDraft);
}

