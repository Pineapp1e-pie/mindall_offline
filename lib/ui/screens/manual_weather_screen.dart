import 'package:flutter/material.dart';
import '../../data/local/app_database.dart';
import '../../data/local/static/weather_labels.dart';
import '../../data/local/tables/context_tags.dart';
import '../../data/local/tables/weather_data.dart';
import '../../domain/models/weather_draft.dart';
import '../widgets/tag_section.dart';

// Импортируем ваши extension'ы
import '../../data/local/static/weather_labels.dart';

class ManualWeatherScreen extends StatefulWidget {
  final Color moodColor;
  final WeatherDraft? initialWeather;

  const ManualWeatherScreen({
    super.key,
    required this.moodColor,
    this.initialWeather,
  });

  @override
  State<ManualWeatherScreen> createState() => _ManualWeatherScreenState();
}

class _ManualWeatherScreenState extends State<ManualWeatherScreen> {
  static const int _cloudinessOffset = 100;
  static const int _temperatureOffset = 200;
  static const int _precipitationOffset = 300;

  int? _selectedCloudinessId;
  int? _selectedTemperatureId;
  int? _selectedPrecipitationId;

  late List<ContextTag> _cloudinessTags;
  late List<ContextTag> _temperatureTags;
  late List<ContextTag> _precipitationTags;

  @override
  void initState() {
    super.initState();

    // Теги облачности - используем labelRu из CloudinessX
    _cloudinessTags = Cloudiness.values.map((cloudiness) {
      return ContextTag(
        id: cloudiness.index + _cloudinessOffset,
        name: cloudiness.labelRu,  // ← используем extension
        type: ContextTagType.cloudiness,
        isCustom: false,
        isActive: false,
      );
    }).toList();

    // Теги температуры - используем labelRu из TemperatureCategoryX
    _temperatureTags = TemperatureCategory.values.map((temperature) {
      // Получаем базовое название (Холодно, Тепло и т.д.)
      final baseName = temperature.labelRu;

      // Добавляем диапазон в зависимости от категории
      String displayName;
      switch (temperature) {
        case TemperatureCategory.veryCold:
          displayName = '$baseName\n≤ -25°C';
          break;
        case TemperatureCategory.cold:
          displayName = '$baseName\n-25°C … -10°C';
          break;
        case TemperatureCategory.cool:
          displayName = '$baseName\n-10°C … +5°C';
          break;
        case TemperatureCategory.comfortable:
          displayName = '$baseName\n+5°C … +20°C';
          break;
        case TemperatureCategory.warm:
          displayName = '$baseName\n+20°C … +30°C';
          break;
        case TemperatureCategory.hot:
          displayName = '$baseName\n≥ +30°C';
          break;
      }

      return ContextTag(
        id: temperature.index + _temperatureOffset,
        name: displayName,  // ← показываем с диапазоном
        type: ContextTagType.temperature,
        isCustom: false,
        isActive: false,
      );
    }).toList();

    // Теги осадков - используем labelRu из PrecipitationTypeX
    _precipitationTags = PrecipitationType.values.map((precipitation) {
      return ContextTag(
        id: precipitation.index + _precipitationOffset,
        name: precipitation.labelRu,  // ← используем extension
        type: ContextTagType.precipitation,
        isCustom: false,
        isActive: false,

      );
    }).toList();

    // Восстановление из initialWeather
    if (widget.initialWeather != null) {
      _selectedCloudinessId = widget.initialWeather!.cloudiness?.index != null
          ? widget.initialWeather!.cloudiness!.index + _cloudinessOffset
          : null;

      _selectedTemperatureId = widget.initialWeather!.temperature?.index != null
          ? widget.initialWeather!.temperature!.index + _temperatureOffset
          : null;

      _selectedPrecipitationId = widget.initialWeather!.precipitation?.index != null
          ? widget.initialWeather!.precipitation!.index + _precipitationOffset
          : null;
    }
  }

  WeatherDraft _buildWeatherDraft() {
    Cloudiness? cloudiness;
    TemperatureCategory? temperature;
    PrecipitationType? precipitation;

    if (_selectedCloudinessId != null) {
      final index = _selectedCloudinessId! - _cloudinessOffset;
      if (index >= 0 && index < Cloudiness.values.length) {
        cloudiness = Cloudiness.values[index];
      }
    }

    if (_selectedTemperatureId != null) {
      final index = _selectedTemperatureId! - _temperatureOffset;
      if (index >= 0 && index < TemperatureCategory.values.length) {
        temperature = TemperatureCategory.values[index];
      }
    }

    if (_selectedPrecipitationId != null) {
      final index = _selectedPrecipitationId! - _precipitationOffset;
      if (index >= 0 && index < PrecipitationType.values.length) {
        precipitation = PrecipitationType.values[index];
      }
    }

    return WeatherDraft(
      cloudiness: cloudiness,
      temperature: temperature,
      precipitation: precipitation,
      source: 'manual',
    );
  }

  void _handleCloudinessToggle(int tagId) {
    setState(() {
      _selectedCloudinessId = _selectedCloudinessId == tagId ? null : tagId;
    });
  }

  void _handleTemperatureToggle(int tagId) {
    setState(() {
      _selectedTemperatureId = _selectedTemperatureId == tagId ? null : tagId;
    });
  }

  void _handlePrecipitationToggle(int tagId) {
    setState(() {
      _selectedPrecipitationId = _selectedPrecipitationId == tagId ? null : tagId;
    });
  }

  bool get _isComplete =>
      _selectedCloudinessId != null &&
          _selectedTemperatureId != null &&
          _selectedPrecipitationId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Укажите погоду',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'DotGothic',
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Облачность
                    TagSection(
                      title: 'Облачность',
                      tags: _cloudinessTags,
                      selectedIds: _selectedCloudinessId != null
                          ? [_selectedCloudinessId!]
                          : [],
                      onToggle: _handleCloudinessToggle,

                    ),

                    const SizedBox(height: 32),

                    // Температура
                    TagSection(
                      title: 'Температура',
                      tags: _temperatureTags,
                      selectedIds: _selectedTemperatureId != null
                          ? [_selectedTemperatureId!]
                          : [],
                      onToggle: _handleTemperatureToggle,

                    ),

                    const SizedBox(height: 32),

                    // Осадки
                    TagSection(
                      title: 'Осадки',
                      tags: _precipitationTags,
                      selectedIds: _selectedPrecipitationId != null
                          ? [_selectedPrecipitationId!]
                          : [],
                      onToggle: _handlePrecipitationToggle,

                    ),

                    const SizedBox(height: 24),

                    if (!_isComplete)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18221C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Выберите по одному варианту в каждой категории',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isComplete
                      ? () {
                    final weatherDraft = _buildWeatherDraft();

                    // Показываем что выбрано (для отладки)
                    print('Выбрано:');
                    print('  Облачность: ${weatherDraft.cloudiness?.labelRu}');
                    print('  Температура: ${weatherDraft.temperature?.labelRu}');
                    print('  Осадки: ${weatherDraft.precipitation?.labelRu}');

                    Navigator.pop(context, weatherDraft);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.moodColor,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    side: const BorderSide(  // ← вместо border используем side
                      color: Color(0xFF555555),
                      width: 2,
                    ),
                    shape: const RoundedRectangleBorder(  // ← убираем скругление
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'DotGothic',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}