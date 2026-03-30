import 'package:flutter/material.dart';

import '../../../domain/models/chart_models.dart';
import 'chart_shared.dart';
import 'day_type_legend.dart';

class MonthCalendar extends StatelessWidget {
  final List<DayStats> dayStats;
  final DateTime month;
  final void Function(DateTime)? onDayTap;

  const MonthCalendar({
    super.key,
    required this.dayStats,
    required this.month,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, DayStats> byDay = {
      for (final ds in dayStats) ds.date.day: ds,
    };

    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = firstDay.weekday - 1;
    const headers = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: headers
              .map(
                (h) => Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (context, i) {
            if (i < offset) return const SizedBox.shrink();
            final day = i - offset + 1;
            final ds = byDay[day];
            final color =
                ds != null ? dayTypeColor(ds.dayType) : Colors.white12;
            return GestureDetector(
              onTap: ds != null
                  ? () =>
                      onDayTap?.call(DateTime(month.year, month.month, day))
                  : null,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 8,
                        color: ds != null ? Colors.white : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const DayTypeLegend(),
      ],
    );
  }
}
