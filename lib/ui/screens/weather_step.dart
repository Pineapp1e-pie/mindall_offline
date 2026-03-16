import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/local/repositories/local_repository.dart';
import '../../data/local/repositories/weather_repository.dart';
import '../../domain/models/mood_entry_draft.dart';
import '../../domain/fill_weather_draft.dart';
import '../widgets/step_indicator.dart';
import '../widgets/bottom_button.dart';
import 'health_step.dart';
import 'weather_content.dart';
import 'manual_weather_screen.dart';

class WeatherStepScreen extends StatefulWidget {
  final MoodEntryDraft draft;
  final Color moodColor;

  const WeatherStepScreen({
    super.key,
    required this.draft,
    required this.moodColor,
  });

  @override
  State<WeatherStepScreen> createState() => _WeatherStepScreenState();
}

class _WeatherStepScreenState extends State<WeatherStepScreen> {
  late MoodEntryDraft _draft;
  late WeatherRepository _weatherRepository;

  bool _loading = false;
  bool _showManualInput = false;

  double? _selectedLat;
  double? _selectedLon;
  String? _selectedCityName;

  final int _currentStep = 2;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;

    _weatherRepository = WeatherRepository(
      client: http.Client(),
      apiKey: 'c2eefad8a813f1bbff076caa61889317',
    );
  }

  Future<void> _detectWeather() async {
    setState(() => _loading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Доступ к местоположению запрещен');
        setState(() => _loading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lon = position.longitude;

      _selectedLat = lat;
      _selectedLon = lon;

      _draft = await fillWeatherDraft(
        draft: _draft,
        repository: _weatherRepository,
        lat: lat,
        lon: lon,
      );

      final cityName = await _getCityNameFromCoordinates(lat, lon);

      setState(() {
        _selectedCityName = cityName;
        _showManualInput = false;
      });

    } catch (e) {
      _showError('Ошибка при определении погоды: $e');
    }

    setState(() => _loading = false);
  }

  Future<String> _getCityNameFromCoordinates(double lat, double lon) async {
    try {
      final url = 'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=${_weatherRepository.apiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final city = data[0];
          final localNames = city['local_names'];
          if (localNames != null && localNames['ru'] != null) {
            return localNames['ru'];
          }
          return city['name'];
        }
      }
    } catch (e) {
      print('Error getting city name: $e');
    }
    return 'Неизвестный город';
  }

  Future<void> _detectWeatherForCity(
      double lat,
      double lon,
      String cityName,
      ) async {
    setState(() {
      _loading = true;
      _selectedCityName = cityName;
      _selectedLat = lat;
      _selectedLon = lon;
      _showManualInput = false;
    });

    _draft = await fillWeatherDraft(
      draft: _draft,
      repository: _weatherRepository,
      lat: lat,
      lon: lon,
    );

    setState(() => _loading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _saveAndContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthStepScreen(
          draft: _draft,
          moodColor: widget.moodColor,
        ),
      ),
    );
  }

  void _navigateToManualInput() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualWeatherScreen(
          moodColor: widget.moodColor,
          initialWeather: _draft.weather,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _draft = _draft.copyWith(weather: result);
        _showManualInput = true;
        _selectedCityName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _draft.weather;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _draft),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _Header(currentStep: _currentStep),

                  if (!_showManualInput) ...[
                    // Компактная строка поиска с иконками
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Поле поиска (занимает всё доступное место)
                          Expanded(
                            child: _PixelSearchField(
                              accentColor: widget.moodColor,
                              onCitySelected: (lat, lon, cityName) {
                                _detectWeatherForCity(lat, lon, cityName);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Иконка автоопределения
                          _CompactIconButton(
                            svgPath: 'lib/ui/assets/pixelariticons_svg/location.svg',  // ← ваш SVG путь
                            color: const Color(0xFFFFFFFF),
                            loading: _loading,
                            onPressed: _loading ? null : _detectWeather,
                            tooltip: 'Определить автоматически', iconColor: Colors.black,
                          ),

                          const SizedBox(width: 8),

                          // Иконка ручного ввода с SVG
                          _CompactIconButton(
                            svgPath: 'lib/ui/assets/pixelariticons_svg/edit-box.svg',  // ← ваш SVG путь
                            color: widget.moodColor,
                            loading: false,
                            onPressed: _navigateToManualInput,
                            tooltip: 'Записать самостоятельно',
                            iconColor: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Информация о выбранном городе
                  if (_selectedCityName != null && !_showManualInput)
                    Padding(
                      padding: const EdgeInsets.all(24),
                        child: Center(
                        child: Row(
                        children: [
                          SvgPicture.asset(
                            'lib/ui/assets/pixelariticons_svg/map-pin.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              widget.moodColor,  // ← вот здесь меняем на moodColor
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedCityName!,
                              style: const TextStyle(
                                fontFamily: 'DotGothic',
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        ],
                      ),),
                    ),
                  // Отображение погоды
                  if (weather != null)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: WeatherContent(
                            weather: weather,
                            loading: _loading,
                            source: _showManualInput ? 'manual' : 'auto',
                            moodColor: widget.moodColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Кнопка Далее
            BottomButton(
              text: 'Далее',
              color: widget.moodColor,
              onTap: _saveAndContinue,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int currentStep;

  const _Header({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          StepIndicator(currentStep: currentStep),
          const SizedBox(height: 24),
          const Text(
            'Какая сегодня\nпогода?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// КОМПАКТНАЯ ИКОНКА-КНОПКА (теперь поддерживает и SVG иконки)
// КОМПАКТНАЯ ИКОНКА-КНОПКА
class _CompactIconButton extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final Color color;
  final Color iconColor;
  final bool loading;
  final VoidCallback? onPressed;
  final String tooltip;

  const _CompactIconButton({
    this.icon,
    this.svgPath,
    required this.color,
    required this.iconColor,
    required this.loading,
    required this.onPressed,
    required this.tooltip,
  }) : assert(icon != null || svgPath != null, 'Either icon or svgPath must be provided');

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: onPressed == null
                ? color.withOpacity(0.3)
                : color,
            border: Border.all(
              color: onPressed == null
                  ? Colors.grey
                  : Colors.white,  // ← вернул белый цвет для рамки
              width: 2,
            ),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : svgPath != null
                ? SvgPicture.asset(
              svgPath!,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                iconColor,  // ← ИСПРАВЛЕНО: используем iconColor вместо Colors.white
                BlendMode.srcIn,
              ),
            )
                : Icon(
              icon,
              color: iconColor,  // ← ИСПРАВЛЕНО: используем iconColor вместо Colors.white
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
class _PixelSearchField extends StatefulWidget {
  final Color accentColor;
  final Function(double lat, double lon, String cityName) onCitySelected;

  const _PixelSearchField({
    required this.accentColor,
    required this.onCitySelected,
  });

  @override
  State<_PixelSearchField> createState() => __PixelSearchFieldState();
}

class __PixelSearchFieldState extends State<_PixelSearchField> {
  static const String apiKey = 'c2eefad8a813f1bbff076caa61889317';

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchCities(String pattern) async {
    if (pattern.isEmpty) return [];

    final url =
        'https://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(pattern)}&limit=5&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Ошибка при поиске городов: $e');
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<Map<String, dynamic>>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(
          fontFamily: 'DotGothic',
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Город',
          hintStyle: const TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white38,
            fontSize: 14,
          ),
          prefixIcon: _PixelIcon(
            Icons.search,
            color: _focusNode.hasFocus ? widget.accentColor : Colors.white70,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? _PixelIconButton(
            icon: Icons.clear,
            color: Colors.white54,
            onPressed: () {
              setState(() {
                _controller.clear();
              });
            },
          )
              : null,
          filled: true,
          fillColor: const Color(0xFF18221C),
          border: _pixelBorder(),
          focusedBorder: _pixelBorder(color: widget.accentColor),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      suggestionsCallback: _fetchCities,
      itemBuilder: (context, city) {
        final localNames = city['local_names'];
        final ruName = localNames != null && localNames['ru'] != null
            ? localNames['ru']
            : city['name'];
        final country = city['country'];
        final state = city['state'];

        String subtitle = country;
        if (state != null) {
          subtitle = '$state, $country';
        }

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: ListTile(
            leading: _PixelIcon(
              Icons.location_on,
              color: widget.accentColor,
            ),
            title: Text(
              ruName,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
      onSuggestionSelected: (city) {
        final localNames = city['local_names'];
        final ruName = localNames != null && localNames['ru'] != null
            ? localNames['ru']
            : city['name'];

        final lat = city['lat'] as double;
        final lon = city['lon'] as double;

        setState(() {
          _controller.text = ruName;
        });

        _focusNode.unfocus();
        widget.onCitySelected(lat, lon, ruName);
      },
      noItemsFoundBuilder: (_) => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Город не найден',
            style: TextStyle(
              fontFamily: 'DotGothic',
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
      ),
      suggestionsBoxDecoration: SuggestionsBoxDecoration(
        color: const Color(0xFF18221C),
        borderRadius: BorderRadius.zero,
        elevation: 8,
      ),
      suggestionsBoxVerticalOffset: 8,
    );
  }

  OutlineInputBorder _pixelBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: color ?? const Color(0xFF555555),
        width: 2,
      ),
    );
  }
}

class _PixelIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _PixelIcon(
      this.icon, {
        required this.color,
        this.size = 20,
      });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: size,
    );
  }
}

class _PixelIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _PixelIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: _PixelIcon(icon, color: color),
      ),
    );
  }
}

class _PixelTextButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _PixelTextButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: color,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}