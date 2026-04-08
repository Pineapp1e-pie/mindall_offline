import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/repositories/local_repository.dart';
import '../models/mood_entry_ui_model.dart';
import '../widgets/pixel_circle.dart';
import '../assets/mood_colors.dart';
import 'mood_category_screen.dart';

import 'mood_entry_detail_screen.dart';

import 'package:provider/provider.dart';




class HomeScreen extends StatelessWidget {
  final List<MoodEntryUiModel> entries;
  final DateTime selectedDate;
  final bool isToday;
  final ValueChanged<DateTime> onDateChanged;

  const HomeScreen({
    super.key,
    required this.entries,
    required this.selectedDate,
    required this.isToday,
    required this.onDateChanged,
  });

  // Детерминированный цвет по дате — не меняется при перерисовке
  Color _colorForDate(DateTime date) {
    final colors = moodColors.values.toList();
    final index = (date.day + date.month * 31) % colors.length;
    return colors[index];
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMM yyyy', 'ru').format(selectedDate);
    final dayColor = _colorForDate(selectedDate);
    const accusative = {
      'среда': 'среду',
      'пятница': 'пятницу',
      'суббота': 'субботу',
    };
    final weekday = DateFormat('EEEE', 'ru').format(selectedDate).toLowerCase();
    final fullDayName = accusative[weekday] ?? weekday;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ---------- Заголовок ----------
            if (isToday)
              const Text(
                'Как себя\nчувствуешь?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 28,
                  color: Colors.white,
                  height: 1.6,
                ),
              )
            else
              Text.rich(



                TextSpan(
                  children: [
                    const TextSpan(text: 'Записи за\n'),
                    TextSpan(
                      text: fullDayName,
                      style: TextStyle(color: dayColor),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 28,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),

            const SizedBox(height: 24),

            // ---------- Кнопка + (только сегодня) ----------
            if (isToday)
              _AddButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MoodCategoryScreen(),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // ---------- ДАТА ----------
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: isToday
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.center,
                  children: [
                    if (isToday)
                      const Text(
                        'Сегодня',
                        style: TextStyle(
                          fontFamily: 'DotGothic',
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontFamily: 'DotGothic',
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.expand_more,
                            color: Colors.white54, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),


            // ---------- КОНТЕНТ ----------


            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        isToday ? 'Нет записей' : 'В этот день\nзаписей нет',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'DotGothic',
                          color: Colors.white24,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _MoodItem(
                    entry: entries[index],
                    index: index,

                  );
                },

              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MoodItem extends StatelessWidget {
  final MoodEntryUiModel entry;
  final int index;

  const _MoodItem({
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = index.isEven;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Align(
        alignment:
        isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MoodEntryDetailScreen(
                  entry: entry,
                  repository: context.read<LocalRepository>(),
                ),
              ),
            );
          },
          child: PixelCircle(
            size: 140,
            pixelSize: 8,
            color: entry.color,
            text: entry.time,
            fontText: 'DotGothic',
            textSize: 24,
          ),
        ),
      ),
    );
  }
}


class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '+',
            style: TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}



