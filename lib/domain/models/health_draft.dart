class HealthDraft {
  final DateTime date;

  final int? sleepMinutes;
  final int? stepsAmount;
  final CyclePhase? cyclePhase;
  final String source; // auto | manual

  HealthDraft({
    required this.date,

    this.sleepMinutes,
    this.stepsAmount,
    this.cyclePhase,
    required this.source,
  });
}

enum CyclePhase {
  menstruation,
  follicular,
  ovulation,
  luteal,
}