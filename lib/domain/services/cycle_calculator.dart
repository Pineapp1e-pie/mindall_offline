import '../models/health_draft.dart';
import '../models/user_profile.dart';

class CycleCalculator {
  static CyclePhase calculate(CycleSettings settings) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final daysSince = today
        .difference(DateTime(
          settings.lastPeriodStart.year,
          settings.lastPeriodStart.month,
          settings.lastPeriodStart.day,
        ))
        .inDays;

    final dayOfCycle = daysSince % settings.cycleLengthDays + 1;

    if (dayOfCycle <= settings.periodDurationDays) {
      return CyclePhase.menstruation;
    }

    // Овуляция обычно за 14 дней до конца цикла
    final ovulationDay = settings.cycleLengthDays - 14;

    if (dayOfCycle >= ovulationDay - 1 && dayOfCycle <= ovulationDay + 1) {
      return CyclePhase.ovulation;
    }

    if (dayOfCycle < ovulationDay - 1) {
      return CyclePhase.follicular;
    }

    return CyclePhase.luteal;
  }
}
