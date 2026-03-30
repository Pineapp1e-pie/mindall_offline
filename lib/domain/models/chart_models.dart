class TimePoint {
  final DateTime time;
  final double value;

  TimePoint(this.time, this.value);
}

class ScatterPoint {
  final double x;
  final double y;
  final String? moodName;

  ScatterPoint(this.x, this.y, {this.moodName});
}

enum DayType { stable, balanced, contrast }

class DayStats {
  final DateTime date;
  final double avgMood;
  final DayType dayType;

  DayStats(this.date, this.avgMood, this.dayType);
}

class MonthQuadrantData {
  final DateTime month;
  final int negativeActive;
  final int positiveActive;
  final int negativeCalm;
  final int positiveCalm;

  MonthQuadrantData(
    this.month, {
    required this.negativeActive,
    required this.positiveActive,
    required this.negativeCalm,
    required this.positiveCalm,
  });

  int get total => negativeActive + positiveActive + negativeCalm + positiveCalm;
}
