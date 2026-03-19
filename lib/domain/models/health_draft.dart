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

  HealthDraft copyWith({
    DateTime? date,
    int? sleepMinutes,
    int? stepsAmount,
    CyclePhase? cyclePhase,
    String? source,
  }) {
    return HealthDraft(
      date: date ?? this.date,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      stepsAmount: stepsAmount ?? this.stepsAmount,
      cyclePhase: cyclePhase ?? this.cyclePhase,
      source: source ?? this.source,
    );
  }
}

enum CyclePhase {
  menstruation,
  follicular,
  ovulation,
  luteal,
}