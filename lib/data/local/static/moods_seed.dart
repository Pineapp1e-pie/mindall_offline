import 'moods.dart';

class MoodSeed {
  final int id;
  final String name;
  final double x;
  final double y;
  final MoodCategory category;

  const MoodSeed({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.category,
  });
}


const moodsSeed = [
  // ───────────── NEGATIVE ACTIVE ─────────────
  MoodSeed(id: 1, name: 'Ярость',        x: -0.9, y:  0.9, category: MoodCategory.negativeActive),
  MoodSeed(id: 2, name: 'Злость',        x: -0.5, y:  0.9, category: MoodCategory.negativeActive),
  MoodSeed(id: 3, name: 'Раздражение',   x: -0.1, y:  0.9, category: MoodCategory.negativeActive),

  MoodSeed(id: 4, name: 'Тревога',       x: -0.9, y:  0.5, category: MoodCategory.negativeActive),
  MoodSeed(id: 5, name: 'Напряжение',    x: -0.5, y:  0.5, category: MoodCategory.negativeActive),
  MoodSeed(id: 6, name: 'Беспокойство',  x: -0.1, y:  0.5, category: MoodCategory.negativeActive),

  MoodSeed(id: 7, name: 'Суета',         x: -0.9, y:  0.1, category: MoodCategory.negativeActive),
  MoodSeed(id: 8, name: 'Смущение',      x: -0.5, y:  0.1, category: MoodCategory.negativeActive),
  MoodSeed(id: 9, name: 'Неуверенность', x: -0.1, y:  0.1, category: MoodCategory.negativeActive),

  // ───────────── NEGATIVE CALM ─────────────
  MoodSeed(id:10, name: 'Уныние',        x: -0.9, y: -0.1, category: MoodCategory.negativeCalm),
  MoodSeed(id:11, name: 'Печаль',        x: -0.5, y: -0.1, category: MoodCategory.negativeCalm),
  MoodSeed(id:12, name: 'Сомнение',      x: -0.1, y: -0.1, category: MoodCategory.negativeCalm),

  MoodSeed(id:13, name: 'Отчаяние',      x: -0.9, y: -0.5, category: MoodCategory.negativeCalm),
  MoodSeed(id:14, name: 'Грусть',        x: -0.5, y: -0.5, category: MoodCategory.negativeCalm),
  MoodSeed(id:15, name: 'Апатия',        x: -0.1, y: -0.5, category: MoodCategory.negativeCalm),

  MoodSeed(id:16, name: 'Опустошение',   x: -0.9, y: -0.9, category: MoodCategory.negativeCalm),
  MoodSeed(id:17, name: 'Одиночество',     x: -0.5, y: -0.9, category: MoodCategory.negativeCalm),
  MoodSeed(id:18, name: 'Безразличие',   x: -0.1, y: -0.9, category: MoodCategory.negativeCalm),

  // ───────────── POSITIVE CALM ─────────────
  MoodSeed(id:19, name: 'Облегчение',    x:  0.1, y: -0.1, category: MoodCategory.positiveCalm),
  MoodSeed(id:20, name: 'Спокойствие',  x:  0.5, y: -0.1, category: MoodCategory.positiveCalm),
  MoodSeed(id:21, name: 'Удовлетворение',x:  0.9, y: -0.1, category: MoodCategory.positiveCalm),

  MoodSeed(id:22, name: 'Расслабленность',x: 0.1, y: -0.5, category: MoodCategory.positiveCalm),
  MoodSeed(id:23, name: 'Комфорт',       x:  0.5, y: -0.5, category: MoodCategory.positiveCalm),
  MoodSeed(id:24, name: 'Гармония',       x:  0.9, y: -0.5, category: MoodCategory.positiveCalm),

  MoodSeed(id:25, name: 'Безмятежность', x:  0.1, y: -0.9, category: MoodCategory.positiveCalm),
  MoodSeed(id:26, name: 'Покой',         x:  0.5, y: -0.9, category: MoodCategory.positiveCalm),
  MoodSeed(id:27, name: 'Умиротворение', x:  0.9, y: -0.9, category: MoodCategory.positiveCalm),

  // ───────────── POSITIVE ACTIVE ─────────────
  MoodSeed(id:28, name: 'Интерес',       x:  0.1, y:  0.1, category: MoodCategory.positiveActive),
  MoodSeed(id:29, name: 'Вдохновение',  x:  0.5, y:  0.1, category: MoodCategory.positiveActive),
  MoodSeed(id:30, name: 'Воодушевление', x:  0.9, y:  0.1, category: MoodCategory.positiveActive),

  MoodSeed(id:31, name: 'Радость',       x:  0.1, y:  0.5, category: MoodCategory.positiveActive),
  MoodSeed(id:32, name: 'Энтузиазм',     x:  0.5, y:  0.5, category: MoodCategory.positiveActive),
  MoodSeed(id:33, name: 'Восторг',       x:  0.9, y:  0.5, category: MoodCategory.positiveActive),

  MoodSeed(id:34, name: 'Счастье',       x:  0.1, y:  0.9, category: MoodCategory.positiveActive),
  MoodSeed(id:35, name: 'Эйфория',       x:  0.5, y:  0.9, category: MoodCategory.positiveActive),
  MoodSeed(id:36, name: 'Экстаз',        x:  0.9, y:  0.9, category: MoodCategory.positiveActive),
];
