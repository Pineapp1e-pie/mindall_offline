import 'package:flutter/material.dart';
import '../../data/local/static/weather_labels.dart';
import '../../data/local/tables/weather_data.dart';
import '../../domain/models/weather_draft.dart';

class WeatherContent extends StatelessWidget {
  final WeatherDraft weather;
  final bool loading;
  final String source; // 'auto' или 'manual'
  final Color moodColor;

  const WeatherContent({
    super.key,
    required this.weather,
    required this.loading,
    required this.source,
    required this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Индикатор источника данных
        _PixelSourceIndicator(
          source: source,
          moodColor: moodColor,
        ),

        const SizedBox(height: 24),

        // Карточка с погодой
        _PixelWeatherCard(
          weather: weather,
        ),
      ],
    );
  }
}

class _PixelSourceIndicator extends StatelessWidget {
  final String source;
  final Color moodColor;

  const _PixelSourceIndicator({
    required this.source,
    required this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    final isAuto = source == 'auto';
    final color = isAuto ? const Color(0xFF84A59D) : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAuto ? Icons.auto_awesome : Icons.edit,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isAuto ? 'АВТООПРЕДЕЛЕНО' : 'УКАЗАНО ВРУЧНУЮ',
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelWeatherCard extends StatelessWidget {
  final WeatherDraft weather;

  const _PixelWeatherCard({
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18221C),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherRow(
            '☁ ОБЛАЧНОСТЬ',
            weather.cloudiness?.labelRu ?? 'НЕ УКАЗАНО',
          ),
          const SizedBox(height: 20),
          _buildWeatherRow(
            '🌡 ТЕМПЕРАТУРА',
            _formatTemperatureWithRange(weather.temperature),
          ),
          const SizedBox(height: 20),
          _buildWeatherRow(
            '🌧 ОСАДКИ',
            weather.precipitation?.labelRu ?? 'НЕ УКАЗАНО',
          ),
        ],
      ),
    );
  }

  String _formatTemperatureWithRange(TemperatureCategory? temperature) {
    if (temperature == null) return 'НЕ УКАЗАНО';

    switch (temperature) {
      case TemperatureCategory.veryCold:
        return 'Холодно: ≤ -25°C';
      case TemperatureCategory.cold:
        return 'Холодно: -25°C … -10°C';
      case TemperatureCategory.cool:
        return 'Прохладно: -10°C … +5°C';
      case TemperatureCategory.comfortable:
        return 'Комфортно: +5°C … +20°C';
      case TemperatureCategory.warm:
        return 'Тепло: +20°C … +30°C';
      case TemperatureCategory.hot:
        return 'Жарко: ≥ +30°C';
    }
  }

  Widget _buildWeatherRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1511),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'DotGothic',
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}