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

//   WeatherDraft copyWith({
//     Cloudiness? cloudiness,
//     TemperatureCategory? temperature,
//     PrecipitationType? precipitation,
//     String? source,
//   }) {
//     return WeatherDraft(
//       cloudiness: cloudiness ?? this.cloudiness,
//       temperature: temperature ?? this.temperature,
//       precipitation: precipitation ?? this.precipitation,
//       source: source ?? this.source,
//     );
//   }
 }