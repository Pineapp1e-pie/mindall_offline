import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../data/local/repositories/weather_repository.dart';
import '../../domain/models/mood_entry_draft.dart';
import '../../domain/fill_weather_draft.dart';

class WeatherStepScreen extends StatefulWidget {
  final MoodEntryDraft draft;

  const WeatherStepScreen({
    super.key,
    required this.draft,
  });

  @override
  State<WeatherStepScreen> createState() => _WeatherStepScreenState();
}

class _WeatherStepScreenState extends State<WeatherStepScreen> {
  late MoodEntryDraft _draft;
  late WeatherRepository _weatherRepository;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;

    _weatherRepository = WeatherRepository(
      client: http.Client(),
      apiKey: 'c2eefad8a813f1bbff076caa61889317', // ← потом вынесешь
    );
  }

  Future<void> _detectWeather() async {
    setState(() => _loading = true);

    _draft = await fillWeatherDraft(
      draft: _draft,
      repository: _weatherRepository,
      lat: 55.75, // временно
      lon: 37.61,
    );

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final weather = _draft.weather;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        title: const Text('Погода'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  /// Шапка
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Какая сегодня погода?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Мы используем её только для анализа настроения',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  /// Контент
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: _loading ? null : _detectWeather,
                            child: const Text('Определить автоматически'),
                          ),

                          const SizedBox(height: 24),

                          if (_loading)
                            const Center(child: CircularProgressIndicator()),

                          if (weather != null) ...[
                            _infoRow('☀️ Солнце', weather.cloudiness.name),
                            if (weather.temperature != null)
                              _infoRow(
                                '🌡 Температура',
                                weather.temperature!.name,
                              ),
                            if (weather.precipitation != null)
                              _infoRow(
                                '🌧 Осадки',
                                weather.precipitation!.name,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Нижняя кнопка
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: weather == null
                  ? null
                  : () {
                Navigator.pop(context, _draft);
              },
              child: const Text('Далее'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
