enum CrisisLevel {
  none,
  softStreak,    // 3 дня подряд негативного настроения
  urgentStreak,  // 7+ дней подряд
  crisis,        // триггерные слова в заметке
}


class CrisisDetector {
  static const List<String> _tier1 = [
    'умереть', 'умирать', 'умру', 'умираю',
    'суицид', 'суицидальный', 'суицидальная',
    'самоубийство', 'самоубийства',
    'повешусь', 'повеситься',
    'отравлюсь', 'отравиться',
    'порежусь', 'вскрою',
    'покончу', 'покончить',
    'выброшусь',
  ];


  static const List<List<String>> _tier2 = [
    ['ненавижу', 'себя'],
    ['убить', 'себя'],
    ['убью', 'себя'],
    ['покончить', 'собой'],
    ['не', 'хочу', 'жить'],
    ['нет', 'смысла', 'жить'],
    ['не', 'вижу', 'смысла'],
    ['хочу', 'исчезнуть'],
    ['незачем', 'жить'],
    ['жить', 'незачем'],
    ['лучше', 'меня', 'не', 'было'],
  ];

  static bool detect(String text) {
    if (text.trim().isEmpty) return false;

    final normalized = _normalize(text);
    final words = _tokenize(normalized);

    for (final trigger in _tier1) {
      for (final word in words) {
        if (_fuzzyMatch(word, trigger)) return true;
      }
    }

    for (final phrase in _tier2) {
      if (_phrasePresent(words, phrase)) return true;
    }

    return false;
  }



  static String _normalize(String text) =>
      text.toLowerCase().replaceAll('ё', 'е');

  static List<String> _tokenize(String text) => text
      .replaceAll(RegExp(r'[^а-яa-z\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  /// Все слова фразы должны найтись среди слов текста.
  static bool _phrasePresent(List<String> textWords, List<String> phrase) {
    for (final phraseWord in phrase) {
      final isNegation = phraseWord == 'не' || phraseWord == 'нет';
      final found = textWords.any((w) {
        if (isNegation) return w == 'не' || w == 'нет';
        if (phraseWord.length <= 2) return w == phraseWord;
        return _fuzzyMatch(w, phraseWord);
      });
      if (!found) return false;
    }
    return true;
  }

  /// Нечёткое сравнение по расстоянию Левенштейна.
  /// Порог: слова ≤ 3 символов — только точное совпадение;
  ///        4–6 символов → 1 ошибка; 7+ → 2 ошибки.
  static bool _fuzzyMatch(String a, String b) {
    if (a == b) return true;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen <= 3) return false;
    final threshold = maxLen >= 7 ? 2 : 1;
    return _levenshtein(a, b) <= threshold;
  }

  static int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var prev = List<int>.generate(b.length + 1, (j) => j);
    var curr = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        curr[j] = a[i - 1] == b[j - 1]
            ? prev[j - 1]
            : 1 + _min3(prev[j], curr[j - 1], prev[j - 1]);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }

  static int _min3(int a, int b, int c) {
    if (a <= b && a <= c) return a;
    return b <= c ? b : c;
  }
}
