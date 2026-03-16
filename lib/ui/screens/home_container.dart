import 'package:flutter/material.dart';
import '../../data/local/app_database.dart';
import '../../data/local/repositories/local_repository_impl.dart';
import '../../domain/models/mood_entry_with_mood.dart';
import '../models/mood_entry_ui_model.dart';
import 'home_screen.dart';
import '../assets/mood_colors.dart';

class HomeContainer extends StatefulWidget {
  const HomeContainer({super.key});

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {

  late Future<List<MoodEntryWithMood>> _future;

  final db = AppDatabase();
  late final repo = LocalRepositoryImpl(db);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = repo.getMoodEntriesForDay(DateTime.now());
  }

  void refresh() {
    setState(() {
      _load();
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MoodEntryWithMood>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E1511),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final entries = snapshot.data!
            .map(_mapToUiModel)
            .toList();

        return HomeScreen(entries: entries);
      },
    );
  }

  MoodEntryUiModel _mapToUiModel(MoodEntryWithMood item) {
    final moodName = item.mood.name;
    final color = moodColors[moodName] ?? Colors.grey;

    return MoodEntryUiModel(
      id: item.entry.id.toString(),
      time: _formatTime(item.entry.createdAt),
      color: color,
      moodName: moodName
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
