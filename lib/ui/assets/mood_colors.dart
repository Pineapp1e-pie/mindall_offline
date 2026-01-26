import 'dart:ui';

Color colorForMood(String moodName) {
  return moodColors[moodName] ?? const Color(0xFF888888);
}

const moodColors = {
  // ───────────── NEGATIVE ACTIVE (верхний левый квадрант: x < 0, y > 0) ─────────────
  // Яркие теплые цвета с уклоном в красные/оранжевые
  'Ярость': Color(0xFFFF5959),
  'Злость': Color(0xFFFF7979),
  'Раздражение': Color(0xFFFFAEAE),

  'Тревога': Color(0xFFFF7979),
  'Напряжение': Color(0xFFFFAEAE),
  'Беспокойство': Color(0xFFFDC7C7),

  'Суета': Color(0xFFFFAEAE),
  'Смущение': Color(0xFFFDC7C7),
  'Неуверенность': Color(0xFFFFE0E0),

  // ───────────── NEGATIVE CALM (нижний левый квадрант: x < 0, y < 0) ─────────────
  // Холодные, приглушенные фиолетовые/синие оттенки
  'Уныние': Color(0xFFB8A1FF),
  'Печаль': Color(0xFFC9B9FA),
  'Сомнение': Color(0xFFE0D7FA),

  'Отчаяние': Color(0xFF9B7BFF),
  'Грусть': Color(0xFFB8A1FF),
  'Апатия': Color(0xFFC9B9FA),

  'Опустошение': Color(0xFF835AFF),
  'Одиночество': Color(0xFF9B7BFF),
  'Безразличие': Color(0xFFB8A1FF),

  // ───────────── POSITIVE CALM (нижний правый квадрант: x > 0, y < 0) ─────────────
  // Свежие зеленые оттенки
  'Облегчение': Color(0xFFD4FCD4),
  'Спокойствие': Color(0xFFB2FCB2),
  'Удовлетворение': Color(0xFF83F483),

  'Расслабленность': Color(0xFFB2FCB2),
  'Комфорт': Color(0xFF83F483),
  'Гармония': Color(0xFF66FF66),

  'Безмятежность': Color(0xFF83F483),
  'Покой': Color(0xFF66FF66),
  'Умиротворение': Color(0xFF46FF46),

  // ───────────── POSITIVE ACTIVE (верхний правый квадрант: x > 0, y > 0) ─────────────
  // Теплые, солнечные желтые/золотые оттенки
  'Интерес': Color(0xFFFFF6CC),
  'Вдохновение': Color(0xFFFFF2B4),
  'Воодушевление': Color(0xFFFFEB89),

  'Радость': Color(0xFFFFF2B4),
  'Энтузиазм': Color(0xFFFFEB89),
  'Восторг': Color(0xFFFCE365),

  'Счастье': Color(0xFFFFEB89),
  'Эйфория': Color(0xFFFCE365),
  'Экстаз': Color(0xFFFFDD3B),
};