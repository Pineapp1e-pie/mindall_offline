import 'package:flutter/material.dart';
import '../../data/local/static/moods.dart';
import '../assets/category_colors.dart';
import '../widgets/pixel_circle.dart';

import 'mood_selection_screen.dart';

class MoodCategoryScreen extends StatelessWidget {
  const MoodCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // ---------- ТЕКСТ ----------
            const Text(
              'Выбери цвет,\nкоторый\nлучше всего\nописывает то,\nкак ты себя чувствуешь',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: "DotGothic",
                fontSize: 24,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 32),

            // ---------- КАТЕГОРИИ ----------
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: MoodCategory.values.map((category) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MoodMatrixScreen(category: category),
                      ),
                    );
                  },
                  child: PixelCircle(
                    size: 160,
                    pixelSize: 10,
                    color: colorForCategory(category),
                    text: categoryLabel(category),
                    fontText: 'Inter',
                    textSize: 14,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String categoryLabel(MoodCategory c) {
    switch (c) {
      case MoodCategory.negativeActive:
        return 'Высокая энергия\nНегативное';
      case MoodCategory.negativeCalm:
        return 'Низкая энергия\nНегативное';
      case MoodCategory.positiveActive:
        return 'Высокая энергия\nПозитивное';
      case MoodCategory.positiveCalm:
        return 'Низкая энергия\nПозитивное';
    }
  }
}
