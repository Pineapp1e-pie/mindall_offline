import 'dart:ui';

import '../../data/local/static/moods.dart';

Color colorForCategory(MoodCategory category) {
  switch (category) {
    case MoodCategory.positiveActive:
      return const Color(0xFFFFDD3B); // жёлтый
    case MoodCategory.positiveCalm:
      return const Color(0xFF46FF46); // голубой
    case MoodCategory.negativeActive:
      return const Color(0xFFFF5959); // красный
    case MoodCategory.negativeCalm:
      return const Color(0xFF835AFF); // серо-синий
  }}