import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherApiResult {
  final double temperature;
  final int clouds;
  final String? condition;

  WeatherApiResult({
    required this.temperature,
    required this.clouds,
    required this.condition,
  });
}

class WeatherRepository {
  final http.Client client;
  final String apiKey;

  WeatherRepository({
    required this.client,
    required this.apiKey,
  });

  Future<WeatherApiResult> fetchWeather({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lon'
          '&units=metric'
          '&appid=$apiKey',
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Weather request failed');
    }

    final jsonData = json.decode(response.body);

    return WeatherApiResult(
      temperature: (jsonData['main']['temp'] as num).toDouble(),
      clouds: jsonData['clouds']['all'] as int,
      condition: jsonData['weather']?[0]?['main'],
    );
  }
}
