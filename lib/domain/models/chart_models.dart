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
