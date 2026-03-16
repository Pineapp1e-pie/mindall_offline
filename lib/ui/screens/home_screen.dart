import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/repositories/local_repository.dart';
import '../models/mood_entry_ui_model.dart';
import '../widgets/pixel_circle.dart';
import 'mood_category_screen.dart';
import 'package:pixelarticons/pixelarticons.dart';

import 'mood_entry_detail_screen.dart';

import 'package:provider/provider.dart';




class HomeScreen extends StatelessWidget {
  final List<MoodEntryUiModel> entries;


  const HomeScreen({
    super.key,
    required this.entries,

  });

  @override
  Widget build(BuildContext context) {

    final now = DateTime.now();
    final formattedDate =
    DateFormat('d MMM yyyy', 'ru').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ---------- Заголовок ----------
            const Text(
              'Как себя\nчувствуешь?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 28,
                color: Colors.white,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            // ---------- Кнопка + ----------
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

            // ---------- СЕГОДНЯ / ДАТА ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Сегодня',
                    style: TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),


            // ---------- КОНТЕНТ ----------


            Expanded(
              child: entries.isEmpty
                  ? const SizedBox()
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
      bottomNavigationBar: const _BottomMenu(),
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


class _BottomMenu extends StatelessWidget {
  const _BottomMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: const Color(0xFF0E1511),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomIcon(
            icon: Pixel.user,
            onTap: () {
              // профиль
            },
          ),
          _BottomIcon(
            isActive: true,
            icon: Pixel.plus,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MoodCategoryScreen(),
                ),
              );
            },
          ),
          _BottomIcon(
            icon: Pixel.chart,
            onTap: () {
              // аналитика
            },
          ),
        ],
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _BottomIcon({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24, // 👈 можно 20–24, пиксельно смотрится
        ),
      ),
    );
  }
}

