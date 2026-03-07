import '../../data/local/tables/weather_data.dart';


class WeatherDraft {
  final Cloudiness? cloudiness;
  final TemperatureCategory? temperature;
  final PrecipitationType? precipitation;
  final String source; // auto | manual

  WeatherDraft({
    this.cloudiness,
    this.temperature,
    this.precipitation,
    required this.source,
  });
}
