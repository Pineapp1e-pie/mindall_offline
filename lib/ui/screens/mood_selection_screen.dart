// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../../data/local/app_database.dart';
// import '../../data/local/static/moods.dart';
// import '../assets/mood_colors.dart';
// import '../widgets/pixel_circle.dart';
//
//
// class MoodMatrixScreen extends StatefulWidget {
//   final MoodCategory category;
//
//
//   const MoodMatrixScreen({
//     super.key,
//     required this.category,
//   });
//
//   @override
//   State<MoodMatrixScreen> createState() => _MoodMatrixScreenState();
// }
//
// class _MoodMatrixScreenState extends State<MoodMatrixScreen> {
//   late final AppDatabase _db;
//   late final TransformationController _controller;
//
//   // Константы для сетки 6×6 с кругами 240px
//   static const double circle = 200; // Размер круга (увеличили до 240)
//   static const double spacing = 60; // Отступ между кругами
//   static const double cell = circle + spacing; // Размер ячейки = круг + отступ
//
//   static const int gridSize = 6; // 6x6 сетка
//
//   // Размер всего поля
//   static double get fieldSize => cell * gridSize; // (240 + 60) * 6 = 1800
//
//   // Центр поля (3 колонка, 3 ряд)
//   static double get gridCenter => cell * 3; // 900
//
//   @override
//   void initState() {
//     super.initState();
//     _db = AppDatabase();
//     _controller = TransformationController();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusCategory();
//     });
//   }
//
//
//
//
//   void _focusCategory() {
//     final screen = MediaQuery.of(context).size;
//     final cellIndex = cellCenterForCategory(widget.category);
//
//     final targetX = cellIndex.dx * cell + cell / 2;
//     final targetY = cellIndex.dy * cell + cell / 2;
//
//     final dx = screen.width / 2 - targetX;
//     final dy = screen.height / 2 - targetY;
//
//     _controller.value = Matrix4.identity()..translate(dx, dy);
//   }
//
//
//
//
//   // Рассчитываем оптимальный масштаб в зависимости от размера экрана
//   double _calculateOptimalScale(Size screen) {
//     // Хотим видеть примерно 2-3 круга по горизонтали
//     final desiredVisibleCircles = 2.5;
//     final desiredWidth = desiredVisibleCircles * cell;
//     return screen.width / desiredWidth;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0E1511),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Матрица настроений - ${_categoryName(widget.category)}',
//           style: const TextStyle(color: Colors.white),
//         ),
//       ),
//       body: FutureBuilder<List<Mood>>(
//         future: _db.select(_db.moods).get(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Ошибка: ${snapshot.error}',
//                 style: const TextStyle(color: Colors.white)));
//           }
//
//           final moods = snapshot.data!;
//
//           // Отладочная информация
//           debugPrint('=== ИНФОРМАЦИЯ О МАТРИЦЕ ===');
//           debugPrint('Круги: $circle px, Отступ: $spacing px, Ячейка: $cell px');
//           debugPrint('Поле: ${fieldSize}x$fieldSize px');
//           debugPrint('Настроений: ${moods.length}');
//           debugPrint('==========================');
//
//           return InteractiveViewer(
//             transformationController: _controller,
//             boundaryMargin: const EdgeInsets.all(double.infinity),
//             minScale: 0.2, // Можно уменьшать сильнее для больших кругов
//             maxScale: 1.0,
//             constrained: false,
//             child: Container(
//               width: fieldSize,
//               height: fieldSize,
//               color: Colors.transparent,
//               child: Stack(
//                 children: [
//                   // Опционально: сетка для отладки
//                   if (false) ..._buildGridLines(), // поставьте true для отображения сетки
//
//                   // Все круги настроений
//                   ...moods.map((mood) {
//                     // Преобразуем координаты из базы [-1,1] в индексы сетки [0,5]
//                     final col = ((mood.x + 1) * 2.5).round().clamp(0, 5);
//                     final row = ((1 - mood.y) * 2.5).round().clamp(0, 5);
//
//                     // Центрируем круг в ячейке
//                     // (cell - circle) / 2 = spacing / 2
//                     final dx = col * cell + spacing / 2;
//                     final dy = row * cell + spacing / 2;
//
//                     // Получаем цвет для настроения
//                     final color = colorForMood(mood.name) ?? _getFallbackColor(mood.category);
//
//                     return Positioned(
//                       left: dx,
//                       top: dy,
//                       child: PixelCircle(
//                         size: circle,
//                         color: color,
//                         text: mood.name,
//                         textSize: _calculateTextSize(circle),
//                         fontText: "Inter",
//                         pixelSize: 11,
//
//                       ),
//                     );
//                   }).toList(),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       // Кнопка для сброса вида
//       // floatingActionButton: FloatingActionButton(
//       //   onPressed: _resetView,
//       //   child: const Icon(Icons.center_focus_weak),
//       //   backgroundColor: Colors.blue,
//       // ),
//     );
//   }
//
//   // Рассчитываем размер текста в зависимости от размера круга
//   double _calculateTextSize(double circleSize) {
//     if (circleSize >= 200) return 16;
//     if (circleSize >= 150) return 14;
//     return 12;
//   }
//
//   Color _getFallbackColor(MoodCategory category) {
//     switch (category) {
//       case MoodCategory.negativeActive:
//         return const Color(0xFFFF5959); // Красный
//       case MoodCategory.positiveActive:
//         return const Color(0xFFFFDD3B); // Желтый (у вас указан желтый код)
//       case MoodCategory.negativeCalm:
//         return const Color(0xFF835AFF); // Фиолетовый
//       case MoodCategory.positiveCalm:
//         return const Color(0xFF46FF46); // Зеленый (у вас указан зеленый код)
//     }
//   }
//
//   String _categoryName(MoodCategory category) {
//     switch (category) {
//       case MoodCategory.negativeActive:
//         return 'Негативные активные';
//       case MoodCategory.positiveActive:
//         return 'Позитивные активные';
//       case MoodCategory.negativeCalm:
//         return 'Негативные спокойные';
//       case MoodCategory.positiveCalm:
//         return 'Позитивные спокойные';
//     }
//   }
//   //
//   // void _resetView() {
//   //   _controller.value = Matrix4.identity();
//   // }
//
//   // Сетка для отладки (опционально)
//   List<Widget> _buildGridLines() {
//     final lines = <Widget>[];
//     for (int i = 0; i <= gridSize; i++) {
//       // Вертикальные линии
//       lines.add(Positioned(
//         left: i * cell,
//         top: 0,
//         child: Container(
//           width: 1,
//           height: fieldSize,
//           color: Colors.white.withOpacity(0.1),
//         ),
//       ));
//       // Горизонтальные линии
//       lines.add(Positioned(
//         left: 0,
//         top: i * cell,
//         child: Container(
//           width: fieldSize,
//           height: 1,
//           color: Colors.white.withOpacity(0.1),
//         ),
//       ));
//     }
//     return lines;
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _db.close();
//     super.dispose();
//   }
// }
//
//
//
// Offset cellCenterForCategory(MoodCategory category) {
//   switch (category) {
//     case MoodCategory.negativeActive:
//       return const Offset(1, 1); // левый верхний квадрант
//     case MoodCategory.positiveActive:
//       return const Offset(4, 1); // правый верх
//     case MoodCategory.negativeCalm:
//       return const Offset(1, 4); // левый низ
//     case MoodCategory.positiveCalm:
//       return const Offset(4, 4); // правый низ
//   }
// }
//
//
//



import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../../data/local/app_database.dart';
import '../../data/local/static/moods.dart';
import '../../domain/models/mood_entry_draft.dart';
import '../assets/mood_colors.dart';
import '../widgets/pixel_circle.dart';
import 'mood_context_screen.dart';

class MoodMatrixScreen extends StatefulWidget {
  final MoodCategory category;

  const MoodMatrixScreen({
    super.key,
    required this.category,
  });

  @override
  State<MoodMatrixScreen> createState() => _MoodMatrixScreenState();

}

class _MoodMatrixScreenState extends State<MoodMatrixScreen> {
  late final AppDatabase _db;
  late final TransformationController _controller;
  Mood? _selectedMood;

  // Константы для сетки 6×6 с кругами 240px
  static const double circle = 200;
  static const double spacing = 60;
  static const double cell = circle + spacing;

  static const int gridSize = 6;
  static double get fieldSize => cell * gridSize;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _controller = TransformationController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusCategory();
    });
  }

  void _focusCategory() {
    final screen = MediaQuery.of(context).size;
    final cellIndex = cellCenterForCategory(widget.category);

    final targetX = cellIndex.dx * cell + cell / 2;
    final targetY = cellIndex.dy * cell + cell / 2;

    final dx = screen.width / 2 - targetX;
    final dy = screen.height / 2 - targetY;

    _controller.value = Matrix4.identity()..translate(dx, dy);
  }

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

      ),
      body: FutureBuilder<List<Mood>>(
        future: _db.select(_db.moods).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final moods = snapshot.data!;

          // Отладочная информация
          debugPrint('=== ИНФОРМАЦИЯ О МАТРИЦЕ ===');
          debugPrint('Круги: $circle px, Отступ: $spacing px, Ячейка: $cell px');
          debugPrint('Поле: ${fieldSize}x$fieldSize px');
          debugPrint('Настроений: ${moods.length}');
          debugPrint('==========================');
          return Stack(
            children: [
              _buildMatrix(moods),
              Positioned(
                left: 24,
                right: 24,
                bottom: 48,
                child: AnimatedSlide(
                  offset: _selectedMood == null
                      ? const Offset(0, 1)
                      : Offset.zero,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _selectedMood == null ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _selectedMood == null
                          ? null
                          : () {
                        final draft = MoodEntryDraft(moodId: _selectedMood!.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MoodContextScreen(
                              draft: draft,
                              moodName: _selectedMood!.name,
                              moodColor: colorForMood(_selectedMood!.name),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity, // Занимает всю доступную ширину
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedMood == null
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF1A1A1A), // Фон всегда #1A1A1A
                          border: Border.all(
                            color: Color(0xFF555555), // Граница белая когда выбрано
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Далее',
                          style: TextStyle(
                            fontFamily: 'DotGothic',
                            fontSize: 16,
                            color: Colors.white, // Текст всегда белый
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatrix(List<Mood> moods) {
    return InteractiveViewer(
      transformationController: _controller,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.2,
      maxScale: 1.0,
      constrained: false,
      child: Container(
        width: fieldSize,
        height: fieldSize,
        color: Colors.transparent,
        child: Stack(
          children: [
            // Опционально: сетка для отладки
            if (false) ..._buildGridLines(),

            // Все круги настроений
            ...moods.map((mood) {
              final col = ((mood.x + 1) * 2.5).round().clamp(0, 5);
              final row = ((1 - mood.y) * 2.5).round().clamp(0, 5);

              final dx = col * cell + spacing / 2;
              final dy = row * cell + spacing / 2;

              final color = colorForMood(mood.name) ?? _getFallbackColor(mood.category);

              return Positioned(
                left: dx,
                top: dy,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood;
                    });
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: _selectedMood == mood ? 1 : 0,
                    ),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return Transform.scale(
                        scale: 1 + 0.15 * value,
                        child: PixelCircle(
                          size: circle,
                          pixelSize: 11,
                          color: color,
                          text: mood.name,
                          textSize: 20,
                          fontText: 'Inter',
                          highlightProgress: value,
                        ),
                      );
                    },
                  ),
                ),

              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getFallbackColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.negativeActive:
        return const Color(0xFFFF5959);
      case MoodCategory.positiveActive:
        return const Color(0xFFFFDD3B);
      case MoodCategory.negativeCalm:
        return const Color(0xFF835AFF);
      case MoodCategory.positiveCalm:
        return const Color(0xFF46FF46);
    }
  }

  String _categoryName(MoodCategory category) {
    switch (category) {
      case MoodCategory.negativeActive:
        return 'Негативные активные';
      case MoodCategory.positiveActive:
        return 'Позитивные активные';
      case MoodCategory.negativeCalm:
        return 'Негативные спокойные';
      case MoodCategory.positiveCalm:
        return 'Позитивные спокойные';
    }
  }

  List<Widget> _buildGridLines() {
    final lines = <Widget>[];
    for (int i = 0; i <= gridSize; i++) {
      lines.add(Positioned(
        left: i * cell,
        top: 0,
        child: Container(
          width: 1,
          height: fieldSize,
          color: Colors.white.withOpacity(0.1),
        ),
      ));
      lines.add(Positioned(
        left: 0,
        top: i * cell,
        child: Container(
          width: fieldSize,
          height: 1,
          color: Colors.white.withOpacity(0.1),
        ),
      ));
    }
    return lines;
  }

  @override
  void dispose() {
    _controller.dispose();
    _db.close();
    super.dispose();
  }
}

Offset cellCenterForCategory(MoodCategory category) {
  switch (category) {
    case MoodCategory.negativeActive:
      return const Offset(1, 1);
    case MoodCategory.positiveActive:
      return const Offset(4, 1);
    case MoodCategory.negativeCalm:
      return const Offset(1, 4);
    case MoodCategory.positiveCalm:
      return const Offset(4, 4);
  }
}

MoodCategory _getOppositeCategory(MoodCategory category) {
  switch (category) {
    case MoodCategory.negativeActive:
      return MoodCategory.positiveActive; // Противоположность негативно-активному
    case MoodCategory.positiveActive:
      return MoodCategory.negativeActive; // Противоположность позитивно-активному
    case MoodCategory.negativeCalm:
      return MoodCategory.positiveCalm; // Противоположность негативно-спокойному
    case MoodCategory.positiveCalm:
      return MoodCategory.negativeCalm; // Противоположность позитивно-спокойному
  }
}