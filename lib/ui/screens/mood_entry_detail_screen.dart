import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';  // 👈 добавить
import 'package:mindall/data/local/static/weather_labels.dart';
import 'dart:io';

import '../../data/local/app_database.dart';
import '../../data/local/repositories/local_repository.dart';
import '../../data/local/tables/context_tags.dart';
import '../../domain/models/health_draft.dart';
import '../models/mood_entry_ui_model.dart';
import '../widgets/tag_section.dart';
import '../screens/health_content.dart';
import '../widgets/voice_player.dart';  // 👈 добавить

class MoodEntryDetailScreen extends StatefulWidget {
  final MoodEntryUiModel entry;
  final LocalRepository repository;

  const MoodEntryDetailScreen({
    super.key,
    required this.entry,
    required this.repository,
  });

  @override
  State<MoodEntryDetailScreen> createState() => _MoodEntryDetailScreenState();
}

class _MoodEntryDetailScreenState extends State<MoodEntryDetailScreen> {
  late Future<Map<String, dynamic>> _data;
  final _player = FlutterSoundPlayer();  // 👈 добавляем
  bool _isPlayerReady = false;  // 👈 добавляем

  @override
  void initState() {
    super.initState();
    _data = _loadData();
    _initPlayer();  // 👈 добавляем
  }

  Future<void> _initPlayer() async {  // 👈 новый метод
    try {
      await _player.openPlayer();
      setState(() {
        _isPlayerReady = true;
      });
    } catch (e) {
      print('Error initializing player: $e');
    }
  }

  @override
  void dispose() {  // 👈 добавляем dispose
    _player.closePlayer();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final entryId = int.tryParse(widget.entry.id) ?? 0;

    final contextDetails =
    await widget.repository.getContextDetailsForEntry(entryId);

    final tags = await widget.repository.getTagsForEntry(entryId);

    final weather = await widget.repository.getWeatherForEntry(entryId);

    final health =
    await widget.repository.getHealthDataForDay(DateTime.now());

    return {
      "context": contextDetails,
      "tags": tags,
      "weather": weather,
      "health": health,
    };
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = widget.entry.color;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Запись",
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Ошибка: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data!;

          final contextDetails = data["context"] as ContextDetail?;
          final weather = data["weather"] as WeatherDataData?;
          final health = data["health"] as HealthDataData?;
          final tags = data["tags"] as List<ContextTag>? ?? [];

          final placeTags =
          tags.where((t) => t.type == ContextTagType.place.name).toList();

          final activityTags =
          tags.where((t) => t.type == ContextTagType.activity.name).toList();

          final socialTags =
          tags.where((t) => t.type == ContextTagType.social.name).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [

              _header(moodColor),

              const SizedBox(height: 32),

              if (placeTags.isNotEmpty)
                TagSection(
                  title: "Место",
                  tags: placeTags,
                  selectedIds: placeTags.map((t) => t.id).toList(),
                  onToggle: (_) {},
                ),

              const SizedBox(height: 24),

              if (activityTags.isNotEmpty)
                TagSection(
                  title: "Действие",
                  tags: activityTags,
                  selectedIds: activityTags.map((t) => t.id).toList(),
                  onToggle: (_) {},
                ),

              const SizedBox(height: 24),

              if (socialTags.isNotEmpty)
                TagSection(
                  title: "Общество",
                  tags: socialTags,
                  selectedIds: socialTags.map((t) => t.id).toList(),
                  onToggle: (_) {},
                ),

              const SizedBox(height: 24),

              if (contextDetails?.note != null)
                _note(contextDetails!.note!),

              if (contextDetails?.photoPath != null)
                _photos(contextDetails!.photoPath!),

              // 👇 используем новый виджет для голоса
              if (contextDetails?.voicePath != null)
                _voice(contextDetails!.voicePath!, moodColor),

              if (weather != null)
                _weather(weather),

              if (health != null)
                HealthContent(
                  health: HealthDraft(
                    date: health.date,
                    sleepMinutes: health.sleepMinutes,
                    stepsAmount: health.stepsAmount,
                    cyclePhase: health.cyclePhase,
                    source: health.source ?? 'manual',
                  ),
                  source: health.source ?? 'manual',
                  moodColor: moodColor,
                ),

              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }

  Widget _header(Color moodColor) {
    return Column(
      children: [
        Text(
          "Запись настроения",
          style: TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 22,
            color: moodColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.entry.time,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _note(String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Заметка",
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18221C),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            note,
            style: const TextStyle(
              fontFamily: 'DotGothic',
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _photos(String path) {
    final file = File(path);

    if (!file.existsSync()) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Фото",
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Image.file(file),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 👇 ОБНОВЛЕННЫЙ МЕТОД _voice
  Widget _voice(String path, Color moodColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Голосовая",
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        VoicePlayerWidget(
          filePath: path,
          accentColor: moodColor,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _weather(WeatherDataData weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Погода",
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
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

              Text(
                weather.temperatureCategory.labelRu,
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "${weather.cloudiness?.labelRu ?? ""} ${weather.precipitation?.labelRu ?? ""}",
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}