import 'package:mindall_offline/ui/app_route.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:mindall_offline/data/local/static/weather_labels.dart';
import 'package:provider/provider.dart';

import '../../data/local/app_database.dart';
import '../../data/local/repositories/local_repository.dart';
import '../../data/local/tables/context_tags.dart';
import '../../data/remote/supabase_sync_service.dart';
import '../../domain/models/health_draft.dart';
import '../models/mood_entry_ui_model.dart';
import '../widgets/voice_player.dart';
import 'mood_context_screen.dart';

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
  final _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _data = _loadData();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.openPlayer();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final entryId = int.tryParse(widget.entry.id) ?? 0;
    final contextDetails =
        await widget.repository.getContextDetailsForEntry(entryId);
    final tags = await widget.repository.getTagsForEntry(entryId);
    final weather = await widget.repository.getWeatherForEntry(entryId);
    final entryDate = widget.entry.createdAt;
    final health = await widget.repository.getHealthDataForDay(
      DateTime(entryDate.year, entryDate.month, entryDate.day),
    );

    return {
      'context': contextDetails,
      'tags': tags,
      'weather': weather,
      'health': health,
    };
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18221C),
        title: const Text(
          'Удалить запись?',
          style: TextStyle(fontFamily: 'DotGothic', color: Colors.white),
        ),
        content: const Text(
          'Это действие нельзя отменить.',
          style: TextStyle(fontFamily: 'DotGothic', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(fontFamily: 'DotGothic', color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить',
                style: TextStyle(fontFamily: 'DotGothic', color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final entryId = int.tryParse(widget.entry.id) ?? 0;
      final entryDate = widget.entry.createdAt;
      final syncService = context.read<SupabaseSyncService>();

      // 1. Удаляем локально
      await widget.repository.deleteMoodEntry(entryId);
      final remaining = await widget.repository.getMoodEntriesForDay(entryDate);
      if (remaining.isEmpty) {
        await widget.repository.deleteHealthDataForDay(entryDate);
        await widget.repository.deleteDailyMoodStatForDay(entryDate);
        await syncService.queueHealthDeletion(entryDate);
      }
      await syncService.queueEntryDeletion(widget.entry.createdAt);

      // 2. Сразу уходим — пользователь не ждёт сеть
      if (mounted) Navigator.pop(context, true);

      // 3. Пробуем удалить из Supabase в фоне (очередь сбросится при syncAll если упадёт)
      unawaited(syncService.flushPendingDeletions());
    }
  }

  Future<void> _editEntry() async {
    final entryId = int.tryParse(widget.entry.id) ?? 0;
    final draft = await widget.repository.getMoodEntryAsDraft(entryId);
    if (!mounted) return;

    Navigator.push(
      context,
      AppRoute(page: MoodContextScreen(
          draft: draft,
          moodName: widget.entry.moodName,
          moodColor: widget.entry.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.entry.color;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: _editEntry,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: color),
            );
          }

          final data = snapshot.data!;
          final contextDetails = data['context'] as ContextDetail?;
          final weather = data['weather'] as WeatherDataData?;
          final health = data['health'] as HealthDataData?;
          final tags = data['tags'] as List<ContextTag>? ?? [];

          final contextTags = tags
              .where((t) =>
                  t.type == ContextTagType.place ||
                  t.type == ContextTagType.activity ||
                  t.type == ContextTagType.social)
              .toList();

          return ListView(
            children: [
              // ── Шапка ──────────────────────────────────────────────
              _Header(entry: widget.entry, color: color),

              // ── Контент ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Теги
                    if (contextTags.isNotEmpty) ...[
                      _TagRow(tags: contextTags),
                      const SizedBox(height: 20),
                    ],

                    // Заметка
                    if (contextDetails?.note != null) ...[
                      _NoteBlock(
                          note: contextDetails!.note!, color: color),
                      const SizedBox(height: 20),
                    ],

                    // Фото
                    if (contextDetails?.photoPath != null) ...[
                      _PhotoBlock(rawPath: contextDetails!.photoPath!),
                      const SizedBox(height: 20),
                    ],

                    // Голос
                    if (contextDetails?.voicePath != null &&
                        contextDetails!.voicePath!.isNotEmpty) ...[
                      _sectionLabel('ГОЛОСОВАЯ'),
                      const SizedBox(height: 8),
                      VoicePlayerWidget(
                        filePath: contextDetails.voicePath ?? '',
                        accentColor: color,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Погода
                    if (weather != null) ...[
                      _WeatherBlock(weather: weather, color: color),
                      const SizedBox(height: 20),
                    ],

                    // Здоровье
                    if (health != null)
                      _HealthBlock(health: health, color: color),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'DotGothic',
        color: Colors.white38,
        fontSize: 11,
        letterSpacing: 2,
      ),
    );
  }
}

// ── Шапка ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final MoodEntryUiModel entry;
  final Color color;

  const _Header({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Цветная полоска-акцент сверху
          Container(width: 48, height: 4, color: color),
          const SizedBox(height: 20),

          Text(
            entry.moodName.toUpperCase(),
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 36,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.time,
            style: const TextStyle(
              fontFamily: 'DotGothic',
              color: Colors.white38,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Теги ────────────────────────────────────────────────────────────────────

class _TagRow extends StatelessWidget {
  final List<ContextTag> tags;

  const _TagRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map((t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Text(
                  t.name,
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Заметка ─────────────────────────────────────────────────────────────────

class _NoteBlock extends StatelessWidget {
  final String note;
  final Color color;

  const _NoteBlock({required this.note, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ЗАМЕТКА',
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Фото ────────────────────────────────────────────────────────────────────

class _PhotoBlock extends StatefulWidget {
  final String rawPath;

  const _PhotoBlock({required this.rawPath});

  @override
  State<_PhotoBlock> createState() => _PhotoBlockState();
}

class _PhotoBlockState extends State<_PhotoBlock> {
  final _controller = PageController();
  int _current = 0;

  List<String> get _paths {
    try {
      final decoded = jsonDecode(widget.rawPath);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [widget.rawPath];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paths = _paths.where((p) => File(p).existsSync()).toList();
    if (paths.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ФОТО',
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _controller,
                itemCount: paths.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => Image.file(
                  File(paths[i]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            if (paths.length > 1)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black54,
                  child: Text(
                    '${_current + 1} / ${paths.length}',
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Погода ──────────────────────────────────────────────────────────────────

class _WeatherBlock extends StatelessWidget {
  final WeatherDataData weather;
  final Color color;

  const _WeatherBlock({required this.weather, required this.color});

  @override
  Widget build(BuildContext context) {
    final conditions = [
      weather.cloudiness?.labelRu,
      weather.precipitation?.labelRu,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ПОГОДА',
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF18221C),
            border: Border(left: BorderSide(color: color, width: 3)),
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
              if (conditions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  conditions,
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Здоровье ────────────────────────────────────────────────────────────────

class _HealthBlock extends StatelessWidget {
  final HealthDataData health;
  final Color color;

  const _HealthBlock({required this.health, required this.color});

  String _formatSleep(int? minutes) {
    if (minutes == null) return '—';
    return '${minutes ~/ 60}ч ${minutes % 60}м';
  }

  String _phaseName(CyclePhase? phase) {
    switch (phase) {
      case CyclePhase.menstruation:
        return 'Менструация';
      case CyclePhase.follicular:
        return 'Фолликулярная';
      case CyclePhase.ovulation:
        return 'Овуляция';
      case CyclePhase.luteal:
        return 'Лютеиновая';
      case null:
        return '—';
    }
  }

  Widget _metricCard(String label, String value, {double rightMargin = 0}) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: rightMargin),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18221C),
          border: Border(top: BorderSide(color: color, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ЗДОРОВЬЕ',
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        // Сон + Шаги в ряд
        Row(
          children: [
            _metricCard('СОН', _formatSleep(health.sleepMinutes),
                rightMargin: 8),
            _metricCard('ШАГИ', health.stepsAmount?.toString() ?? '—'),
          ],
        ),
        // Цикл на всю ширину (только если есть)
        if (health.cyclePhase != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF18221C),
              border: Border(top: BorderSide(color: color, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ЦИКЛ',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _phaseName(health.cyclePhase),
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
