import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mindall/data/local/static/weather_labels.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/local/app_database.dart';
import '../../data/local/repositories/local_repository.dart';
import '../../data/local/static/moods.dart';
import '../../data/local/tables/weather_data.dart';
import '../../ui/assets/category_colors.dart';
import '../../ui/assets/mood_colors.dart';
import '../models/chart_models.dart';
import '../models/health_draft.dart';
import '../models/mood_entry_with_mood.dart';
import 'subscription_service.dart';

// Вспомогательный класс: запись настроения + её детали + теги (для дневного PDF)
class _DayEntry {
  final MoodEntryWithMood item;
  final ContextDetail? details;
  final List<ContextTag> tags;

  _DayEntry(this.item, this.details, this.tags);
}

// Точка корреляции: среднее настроение дня/месяца + данные здоровья.
class _DayCorr {
  final DateTime date;
  final double avgMood; // -1..+1
  final double? sleep; // часы (sleepMinutes / 60)
  final double? steps; // шаги
  final CyclePhase? cyclePhase;

  _DayCorr(this.date, this.avgMood, {this.sleep, this.steps, this.cyclePhase});
}

class ExportService {
  final LocalRepository _repo;
  final SubscriptionService _subscriptionService;

  ExportService(this._repo, this._subscriptionService);

  Future<void> _ensureExportAccess() {
    return _subscriptionService.ensureAccess(SubscriptionFeature.exportData);
  }

  // ─────────────────────────────────────────────────
  // Excel: все записи за период
  // ─────────────────────────────────────────────────

  Future<String> exportEntriesToExcel(DateTime from, DateTime to) async {
    await _ensureExportAccess();

    final entries = await _repo.getMoodEntriesWithMoodForPeriod(from, to);
    entries.sort((a, b) => a.entry.createdAt.compareTo(b.entry.createdAt));

    // 1. Загружаем теги для всех записей (Map<entryId, List<ContextTag>>)
    final tagsMap = <int, List<ContextTag>>{};
    for (final e in entries) {
      final tags = await _repo.getTagsForEntry(e.entry.id);
      tagsMap[e.entry.id] = tags;
    }

    // 2. Загружаем данные здоровья по дням (Map<dayKey, HealthDataData>)
    final healthMap = <int, HealthDataData>{};
    final healthDataList = await _repo.getHealthDataForPeriod(from, to);
    for (final h in healthDataList) {
      final dayKey = DateTime(h.date.year, h.date.month, h.date.day).millisecondsSinceEpoch;
      healthMap[dayKey] = h;
    }

    // 3. Загружаем погоду для каждой записи (Map<entryId, WeatherDataData>)
    final weatherMap = <int, WeatherDataData>{};
    for (final e in entries) {
      final weather = await _repo.getWeatherForEntry(e.entry.id);
      if (weather != null) weatherMap[e.entry.id] = weather;
    }

    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Записи');
    final sheet = excel['Записи'];

    final headers = [
      'Дата', 'Время', 'Настроение', 'Квадрант', 'Теги', 'Заметка',
      'Шаги', 'Сон (ч)', 'Фаза цикла', 'Температура', 'Осадки', 'Облачность'
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    final dateFmt = DateFormat('dd.MM.yyyy');
    final timeFmt = DateFormat('HH:mm');

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final row = i + 1;

      // Базовая информация
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(dateFmt.format(e.entry.createdAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(timeFmt.format(e.entry.createdAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(e.mood.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(_categoryLabel(e.mood.category));

      // Теги (колонка 4)
      final tags = tagsMap[e.entry.id] ?? [];
      final tagsStr = tags.map((t) => t.name).join(', ');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(tagsStr);

      // Заметка (колонка 5)
      final details = await _repo.getContextDetailsForEntry(e.entry.id);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(details?.note ?? '');

      // Данные здоровья за день (колонки 6,7,8)
      final dayKey = DateTime(e.entry.createdAt.year, e.entry.createdAt.month, e.entry.createdAt.day)
          .millisecondsSinceEpoch;
      final health = healthMap[dayKey];
      if (health != null) {
        // Шаги
        if (health.stepsAmount != null) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
              .value = IntCellValue(health.stepsAmount!);
        }
        // Сон (часы)
        if (health.sleepMinutes != null) {
          final sleepHours = (health.sleepMinutes! / 60).toStringAsFixed(1);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
              .value = TextCellValue(sleepHours);
        }
        // Фаза цикла
        if (health.cyclePhase != null) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
              .value = TextCellValue(_cycleLabel(health.cyclePhase!));
        }
      }

      // Погода (колонки 9,10,11) – используем ваши расширения
      final weather = weatherMap[e.entry.id];
      if (weather != null) {
        // Температура
        final tempStr = weather.rawTemperature != null
            ? '${weather.rawTemperature!.toStringAsFixed(0)}°C'
            : weather.temperatureCategory.labelRu;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
            .value = TextCellValue(tempStr);

        // Осадки
        final precipStr = weather.precipitation?.labelRu ?? '';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
            .value = TextCellValue(precipStr);

        // Облачность
        final cloudStr = weather.cloudiness?.labelRu ?? '';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
            .value = TextCellValue(cloudStr);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);
    final path = '${dir.path}/миндаль_${fromStr}_$toStr.xlsx';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Ошибка при создании Excel-файла');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  // ─────────────────────────────────────────────────
  // PDF: аналитика за период (неделя / месяц / год)
  // ─────────────────────────────────────────────────

  Future<List<int>> exportAnalyticsToPdfBytes(
    DateTime from,
    DateTime to,
    String periodLabel, {
    bool isYear = false,
    bool trackCycle = false,
  }) async {
    await _ensureExportAccess();

    final fontData = await rootBundle.load(
      'lib/ui/assets/fonts/Inter-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    final base = pw.TextStyle(font: ttf, fontSize: 11);
    final h1 = pw.TextStyle(
      font: ttf,
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final h2 = pw.TextStyle(
      font: ttf,
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    final small = pw.TextStyle(
      font: ttf,
      fontSize: 9,
      color: PdfColors.grey600,
    );
    final grey = base.copyWith(color: PdfColors.grey600);

    // ── Основные данные + данные для корреляций ──
    final entries = await _repo.getMoodEntriesWithMoodForPeriod(from, to);
    final healthData = await _repo.getHealthDataForPeriod(from, to);
    final weatherPairs = await _repo.getMoodWeatherPairs(from, to);

    final total = entries.length;
    final avgMood = total > 0
        ? entries.map((e) => e.mood.x).reduce((a, b) => a + b) / total
        : 0.0;

    // Среднее настроение по дням (используется для корреляций в обоих ветках)
    final dayAvgMood = <DateTime, double>{};
    {
      final tmp = <DateTime, List<double>>{};
      for (final e in entries) {
        final d = e.entry.createdAt;
        final day = DateTime(d.year, d.month, d.day);
        tmp.putIfAbsent(day, () => []).add(e.mood.x);
      }
      for (final kv in tmp.entries) {
        dayAvgMood[kv.key] = kv.value.reduce((a, b) => a + b) / kv.value.length;
      }
    }

    // Здоровье по дням
    final healthByDay = <DateTime, HealthDataData>{};
    for (final h in healthData) {
      healthByDay[DateTime(h.date.year, h.date.month, h.date.day)] = h;
    }

    // Scatter-точки для корреляций: одна точка = одна запись настроения
    final sleepScatter = <ScatterPoint>[]; // X=сон ч,    Y=настроение
    final stepsScatter = <ScatterPoint>[]; // X=шаги тыс, Y=настроение
    final cycleScatter = <ScatterPoint>[]; // X=настроение, Y=фаза 0-3
    final weatherScatter = <ScatterPoint>[]; // X=категория 0-5, Y=настроение
    {
      final byDay = <DateTime, List<MoodEntryWithMood>>{};
      for (final e in entries) {
        final d = e.entry.createdAt;
        final day = DateTime(d.year, d.month, d.day);
        byDay.putIfAbsent(day, () => []).add(e);
      }
      for (final kv in byDay.entries) {
        final h = healthByDay[kv.key];
        if (h == null) continue;
        for (final e in kv.value) {
          if (h.sleepMinutes != null) {
            sleepScatter.add(
              ScatterPoint(
                h.sleepMinutes! / 60.0,
                e.mood.x,
                moodName: e.mood.name,
              ),
            );
          }
          if (h.stepsAmount != null) {
            stepsScatter.add(
              ScatterPoint(
                h.stepsAmount! / 1000.0,
                e.mood.x,
                moodName: e.mood.name,
              ),
            );
          }
          if (trackCycle && h.cyclePhase != null) {
            cycleScatter.add(
              ScatterPoint(
                e.mood.x, // X = mood -1..+1
                _cyclePhaseIndex(h.cyclePhase!).toDouble(), // Y = phase 0-3
                moodName: e.mood.name,
              ),
            );
          }
        }
      }
    }
    for (final p in weatherPairs) {
      weatherScatter.add(
        ScatterPoint(
          _tempCatIdx(p.temperatureCategory).toDouble(),
          p.moodX,
          moodName: p.moodName,
        ),
      );
    }

    // Квадранты — подсчёт из уже загруженных entries (без повторного DB-запроса)
    final quadrants = <MoodCategory, int>{
      MoodCategory.negativeActive: 0,
      MoodCategory.positiveActive: 0,
      MoodCategory.negativeCalm: 0,
      MoodCategory.positiveCalm: 0,
    };
    for (final e in entries) {
      quadrants[e.mood.category] = (quadrants[e.mood.category] ?? 0) + 1;
    }

    // ── Топ-5 настроений (используется на обеих страницах) ──
    final moodCounts = <String, int>{};
    for (final e in entries) {
      moodCounts[e.mood.name] = (moodCounts[e.mood.name] ?? 0) + 1;
    }
    final top5 =
        (moodCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .toList();
    final maxMoodCount = top5.isNotEmpty ? top5.first.value : 1;

    // ── Цвета типов дней ──
    final stableColor = _toPdfColor(const Color(0xFF7EC8E3));
    final balancedColor = _toPdfColor(const Color(0xFFB8A9E3));
    final contrastColor = _toPdfColor(const Color(0xFFF4A261));

    // ═══════════════════════════════════════════════════
    // Локальные хелперы виджетов (захватывают ttf/стили)
    // ═══════════════════════════════════════════════════

    // Карточка со статистической метрикой
    pw.Widget statCard(String label, String value) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(label, style: small),
          ],
        ),
      ),
    );

    // Блок инсайтов с фиолетовой левой полоской
    pw.Widget insightBlock(List<String> lines) => pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.purple50,
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.purple300, width: 3),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(l, style: base),
            ),
        ],
      ),
    );

    // Заголовок секции с опциональным серым подзаголовком
    pw.Widget sectionH(String title, {String? subtitle}) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: h2),
        if (subtitle != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(subtitle, style: grey),
        ],
        pw.SizedBox(height: 12),
      ],
    );

    // Карточка квадранта (цветная рамка, описание, счётчик)
    pw.Widget quadrantCard(MoodCategory cat, String desc) {
      final count = quadrants[cat] ?? 0;
      final pct = total > 0 ? '${(count / total * 100).round()}%' : '0%';
      final color = _toPdfColor(colorForCategory(cat));
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.all(3),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color, width: 1.2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _categoryLabel(cat),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(desc, style: small),
              pw.SizedBox(height: 6),
              pw.Text(
                '$count · $pct',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Горизонтальный мини-бар: заполненный прямоугольник на фоне серого
    const barMaxW = 130.0;
    const barH = 8.0;
    pw.Widget inlineBar(double pct, PdfColor color) => pw.Stack(
      children: [
        pw.Container(
          width: barMaxW,
          height: barH,
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        ),
        if (pct > 0)
          pw.Container(
            width: barMaxW * pct.clamp(0.0, 1.0),
            height: barH,
            decoration: pw.BoxDecoration(color: color),
          ),
      ],
    );

    // Строка: название + бар + правый лейбл
    pw.Widget barRow(String label, double pct, PdfColor color, String right) =>
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 120, child: pw.Text(label, style: base)),
              pw.SizedBox(width: 8),
              inlineBar(pct, color),
              pw.SizedBox(width: 8),
              pw.Text(right, style: grey),
            ],
          ),
        );

    // ─────────────────────────────────────────────────────────────────────
    // Страница корреляций: scatter-графики как в экране CorrelationScreen.
    // Каждая точка = одна запись настроения + соответствующая метрика дня.
    // ─────────────────────────────────────────────────────────────────────
    List<pw.Widget> corrPage(
      List<_DayCorr> corrData,
      String Function(DateTime) labelFn,
    ) {
      final hasSleep = sleepScatter.isNotEmpty;
      final hasSteps = stepsScatter.isNotEmpty;
      final hasTempData = weatherScatter.isNotEmpty;
      final hasCycleData = trackCycle && cycleScatter.isNotEmpty;
      final hasAny = hasSleep || hasSteps || hasTempData || hasCycleData;

      return [
        pw.Text('Настроение и факторы', style: h1),
        pw.SizedBox(height: 6),
        pw.Text(periodLabel, style: grey),
        pw.Divider(height: 32, color: PdfColors.grey300),

        if (!hasAny)
          pw.Text(
            'Недостаточно данных для построения корреляций.\n'
            'Добавляйте данные о сне и шагах для более детального анализа.',
            style: grey,
          ),

        if (hasSleep) ...[
          sectionH('Сон и настроение'),
          pw.Text(
            'По горизонтали — часы сна за день, по вертикали — настроение '
            'от −1 (плохое) до +1 (хорошее). Каждая точка — одна запись '
            'настроения в день с данными о сне. Если точки скапливаются '
            'правее и выше — больше сна связано с лучшим настроением.',
            style: grey,
          ),
          pw.SizedBox(height: 16),
          _buildScatterChart(sleepScatter, 'ч', ttf),
          pw.SizedBox(height: 36),
        ],

        if (hasSteps) ...[
          sectionH('Шаги и настроение'),
          pw.Text(
            'По горизонтали — количество шагов за день, по вертикали — '
            'настроение от −1 (плохое) до +1 (хорошее). Каждая точка — одна '
            'запись настроения. Если точки правее и выше — больше активности '
            'связано с лучшим настроением.',
            style: grey,
          ),
          pw.SizedBox(height: 16),
          _buildScatterChart(stepsScatter, 'тыс', ttf),
          pw.SizedBox(height: 36),
        ],

        if (hasTempData) ...[
          sectionH('Погода и настроение'),
          pw.Text(
            'По горизонтали — категория температуры (от очень холодно до '
            'жарко), по вертикали — настроение. Смотри в каком столбце точки '
            'расположены выше — при такой погоде настроение обычно лучше.',
            style: grey,
          ),
          pw.SizedBox(height: 16),
          _buildWeatherScatterChart(weatherScatter, ttf),
          pw.SizedBox(height: 36),
        ],

        if (hasCycleData) ...[
          sectionH('Цикл и настроение'),
          pw.Text(
            'По горизонтали — настроение от −1 (плохое) до +1 (хорошее), '
            'по вертикали — фаза цикла. Смотри в какой строке точки '
            'сдвинуты правее — в эту фазу настроение обычно лучше.',
            style: grey,
          ),
          pw.SizedBox(height: 16),
          _buildCycleScatterChart(cycleScatter, ttf),
        ],
      ];
    }

    // Страница квадрантов + топ настроений (общая для год / неделя / месяц)
    List<pw.Widget> detailsPage() => [
      sectionH(
        'Квадранты настроения',
        subtitle: 'Настроения делятся на 4 типа по уровню энергии и знаку',
      ),
      pw.Row(
        children: [
          quadrantCard(
            MoodCategory.positiveActive,
            'радость, восторг, энтузиазм',
          ),
          quadrantCard(MoodCategory.positiveCalm, 'покой, гармония, комфорт'),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          quadrantCard(
            MoodCategory.negativeActive,
            'злость, тревога, раздражение',
          ),
          quadrantCard(
            MoodCategory.negativeCalm,
            'грусть, апатия, одиночество',
          ),
        ],
      ),
      pw.SizedBox(height: 32),
      if (total > 0) ...[
        sectionH('Распределение по квадрантам'),
        _buildQuadrantBars(quadrants, ttf),
        pw.SizedBox(height: 32),
      ],
      sectionH('Топ настроений'),
      ...top5.map(
        (e) => barRow(
          e.key,
          e.value / maxMoodCount,
          _toPdfColor(colorForMood(e.key)),
          '${e.value} · ${_pct(e.value, total)}',
        ),
      ),
    ];

    // ═══════════════════════════════════════════
    final pdf = pw.Document();

    if (isYear) {
      // ──────────────────────────────────────────
      // ГОД: 2 страницы
      // ──────────────────────────────────────────
      final year = from.year;

      // Группируем entries по месяцам — без повторного DB-запроса
      final byMonth = List.generate(
        12,
        (_) => <MoodCategory, int>{
          MoodCategory.negativeActive: 0,
          MoodCategory.positiveActive: 0,
          MoodCategory.negativeCalm: 0,
          MoodCategory.positiveCalm: 0,
        },
      );
      for (final e in entries) {
        final m = e.entry.createdAt.month - 1;
        byMonth[m][e.mood.category] = (byMonth[m][e.mood.category] ?? 0) + 1;
      }
      final yearData = List.generate(
        12,
        (i) => MonthQuadrantData(
          DateTime(year, i + 1, 1),
          negativeActive: byMonth[i][MoodCategory.negativeActive]!,
          positiveActive: byMonth[i][MoodCategory.positiveActive]!,
          negativeCalm: byMonth[i][MoodCategory.negativeCalm]!,
          positiveCalm: byMonth[i][MoodCategory.positiveCalm]!,
        ),
      );

      final activeMonths = yearData.where((m) => m.total > 0).length;
      final yearTotal = yearData.fold(0, (s, m) => s + m.total);

      // Лучший месяц — по соотношению позитив/негатив
      MapEntry<DateTime, double>? bestMonth;
      for (final m in yearData) {
        if (m.total == 0) continue;
        final score =
            (m.positiveActive +
                m.positiveCalm -
                m.negativeActive -
                m.negativeCalm) /
            m.total;
        if (bestMonth == null || score > bestMonth.value) {
          bestMonth = MapEntry(m.month, score);
        }
      }

      // Самый активный месяц
      final mostActive = yearData
          .where((m) => m.total > 0)
          .fold<MonthQuadrantData?>(
            null,
            (prev, m) => prev == null || m.total > prev.total ? m : prev,
          );

      final yearInsights = <String>[
        if (total > 0) 'Общий тон года: ${_moodLabel(avgMood)}.',
        if (bestMonth != null)
          'Лучший месяц — ${DateFormat('MMMM', 'ru').format(bestMonth.key)} '
              '(${_moodLabel(bestMonth.value)}).',
        if (mostActive != null)
          'Самый активный месяц — ${DateFormat('MMMM', 'ru').format(mostActive.month)} '
              '(${mostActive.total} ${_pluralEntries(mostActive.total)}).',
      ];

      // Цвета сегментов стекового бара
      final paColor = _toPdfColor(const Color(0xFFFFDD3B));
      final pcColor = _toPdfColor(const Color(0xFF46FF46));
      final naColor = _toPdfColor(const Color(0xFFFF5959));
      final ncColor = _toPdfColor(const Color(0xFF835AFF));

      // ── Корреляционные данные по месяцам (для 3-й страницы) ──
      final moodSumByM = List<double>.filled(12, 0);
      final moodCntByM = List<int>.filled(12, 0);
      for (final e in entries) {
        final m = e.entry.createdAt.month - 1;
        moodSumByM[m] += e.mood.x;
        moodCntByM[m]++;
      }
      final sleepSumByM = List<double>.filled(12, 0);
      final sleepCntByM = List<int>.filled(12, 0);
      final stepsSumByM = List<double>.filled(12, 0);
      final stepsCntByM = List<int>.filled(12, 0);
      for (final h in healthData) {
        final m = h.date.month - 1;
        if (h.sleepMinutes != null) {
          sleepSumByM[m] += h.sleepMinutes!;
          sleepCntByM[m]++;
        }
        if (h.stepsAmount != null) {
          stepsSumByM[m] += h.stepsAmount!;
          stepsCntByM[m]++;
        }
      }
      final yearCorrData = <_DayCorr>[
        for (var i = 0; i < 12; i++)
          if (moodCntByM[i] > 0)
            _DayCorr(
              DateTime(year, i + 1, 1),
              moodSumByM[i] / moodCntByM[i],
              sleep: sleepCntByM[i] > 0
                  ? sleepSumByM[i] / sleepCntByM[i] / 60.0
                  : null,
              steps: stepsCntByM[i] > 0
                  ? stepsSumByM[i] / stepsCntByM[i]
                  : null,
            ),
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(base: ttf),
          build: (ctx) => [
            // ── Стр. 1: Обзор года ──
            pw.Text('Год в настроениях', style: h1),
            pw.SizedBox(height: 6),
            pw.Text('$year', style: grey),
            pw.Divider(height: 32, color: PdfColors.grey300),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                statCard('Записей за год', '$yearTotal'),
                pw.SizedBox(width: 8),
                statCard('Активных месяцев', '$activeMonths / 12'),
                pw.SizedBox(width: 8),
                statCard('Средний тон', _moodLabel(avgMood)),
              ],
            ),
            pw.SizedBox(height: 32),

            sectionH(
              'Динамика по месяцам',
              subtitle: 'Количество записей по квадрантам настроений',
            ),

            // 100% stacked bar по месяцам: все столбики одной высоты (90pt),
            // сегменты отражают долю каждого квадранта внутри месяца.
            // Месяц без записей — пустой серый столбик той же высоты.
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: List.generate(12, (i) {
                    final m = yearData[i];
                    const fullH = 90.0;
                    const slotW = 515.0 / 12;
                    const bw = slotW * 0.65;
                    if (m.total == 0) {
                      // Нет данных — серый пустой столбик
                      return pw.SizedBox(
                        width: slotW,
                        child: pw.Center(
                          child: pw.Container(
                            width: bw,
                            height: fullH,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.grey200,
                            ),
                          ),
                        ),
                      );
                    }
                    // Высота каждого сегмента = доля * fullH
                    final t = m.total.toDouble();
                    return pw.SizedBox(
                      width: slotW,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          if (m.positiveActive > 0)
                            pw.Container(
                              width: bw,
                              height: m.positiveActive / t * fullH,
                              decoration: pw.BoxDecoration(color: paColor),
                            ),
                          if (m.positiveCalm > 0)
                            pw.Container(
                              width: bw,
                              height: m.positiveCalm / t * fullH,
                              decoration: pw.BoxDecoration(color: pcColor),
                            ),
                          if (m.negativeCalm > 0)
                            pw.Container(
                              width: bw,
                              height: m.negativeCalm / t * fullH,
                              decoration: pw.BoxDecoration(color: ncColor),
                            ),
                          if (m.negativeActive > 0)
                            pw.Container(
                              width: bw,
                              height: m.negativeActive / t * fullH,
                              decoration: pw.BoxDecoration(color: naColor),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
                // Подписи месяцев
                pw.Row(
                  children: List.generate(12, (i) {
                    final label = DateFormat(
                      'LLL',
                      'ru',
                    ).format(DateTime(year, i + 1)).replaceAll('.', '');
                    return pw.SizedBox(
                      width: 515.0 / 12,
                      child: pw.Center(
                        child: pw.Text(
                          label,
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 7,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            // Легенда
            pw.SizedBox(height: 14),
            pw.Row(
              children: [
                _legendItem(paColor, 'Акт. позитивное', ttf),
                pw.SizedBox(width: 10),
                _legendItem(pcColor, 'Спок. позитивное', ttf),
                pw.SizedBox(width: 10),
                _legendItem(ncColor, 'Спок. негативное', ttf),
                pw.SizedBox(width: 10),
                _legendItem(naColor, 'Акт. негативное', ttf),
              ],
            ),

            pw.SizedBox(height: 28),
            if (yearInsights.isNotEmpty) insightBlock(yearInsights),

            // ── Стр. 2: Детали ──
            pw.NewPage(),
            ...detailsPage(),

            // ── Стр. 3: Корреляции ──
            pw.NewPage(),
            ...corrPage(
              yearCorrData,
              (d) => DateFormat('LLL', 'ru').format(d).replaceAll('.', ''),
            ),
          ],
        ),
      );
    } else {
      // ──────────────────────────────────────────
      // НЕДЕЛЯ / МЕСЯЦ: 2 страницы
      // ──────────────────────────────────────────

      // Timeline: среднее настроение по дням — из уже загруженных entries
      final byDayX = <DateTime, List<double>>{};
      final byDayEntries = <DateTime, List<MoodEntryWithMood>>{};
      for (final e in entries) {
        final d = e.entry.createdAt;
        final day = DateTime(d.year, d.month, d.day);
        byDayX.putIfAbsent(day, () => []).add(e.mood.x);
        byDayEntries.putIfAbsent(day, () => []).add(e);
      }
      final timeline =
          (byDayX.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map(
            (e) {
              final avg = e.value.reduce((a, b) => a + b) / e.value.length;
              return TimePoint(e.key, avg);
            },
          ).toList();

      // DayStats: тип дня — из тех же сгруппированных данных
      final dayStats =
          (byDayEntries.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key)))
              .map((e) {
                final dayEntries = e.value;
                final avg =
                    dayEntries.map((x) => x.mood.x).reduce((a, b) => a + b) /
                    dayEntries.length;
                return DayStats(e.key, avg, _calcDayType(dayEntries));
              })
              .toList();

      final daysWithEntries = timeline.length;
      final totalDays = to.difference(from).inDays + 1;
      final isWeek = totalDays <= 7;

      final stableCount = dayStats
          .where((d) => d.dayType == DayType.stable)
          .length;
      final balancedCount = dayStats
          .where((d) => d.dayType == DayType.balanced)
          .length;
      final contrastCount = dayStats
          .where((d) => d.dayType == DayType.contrast)
          .length;
      final dayTotal = dayStats.length;

      // Инсайты периода
      final positiveDays = timeline.where((p) => p.value > 0).length;
      final insights = <String>[
        if (timeline.isNotEmpty)
          '$positiveDays из ${timeline.length} ${_pluralDays(timeline.length)} '
              'были позитивными.',
        if (timeline.isNotEmpty)
          'Лучший день — ${DateFormat('EEEE, dd.MM.yyyy', 'ru').format(timeline.reduce((a, b) => a.value >= b.value ? a : b).time)} (${_moodLabel(timeline.reduce((a, b) => a.value >= b.value ? a : b).value)}).',
        if (contrastCount > 0)
          '$contrastCount ${_pluralDays(contrastCount)}  '
              'с резкими перепадами настроения.',
      ];

      // Подписи X оси: до 7 дней — день недели, иначе — число
      final shortLabels = timeline.length <= 7;

      // ── Корреляционные данные по дням (для 3-й страницы) ──
      final corrData =
          (dayAvgMood.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
              .map((kv) {
                final h = healthByDay[kv.key];
                return _DayCorr(
                  kv.key,
                  kv.value,
                  sleep: h?.sleepMinutes != null
                      ? h!.sleepMinutes! / 60.0
                      : null,
                  steps: h?.stepsAmount?.toDouble(),
                  cyclePhase: h?.cyclePhase,
                );
              })
              .toList();
      final corrLabel = shortLabels
          ? (DateTime d) => DateFormat('EE', 'ru').format(d)
          : (DateTime d) => d.day.toString();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(base: ttf),
          build: (ctx) => [
            // ── Стр. 1: Обзор ──
            pw.Text('Аналитика настроения', style: h1),
            pw.SizedBox(height: 6),
            pw.Text(periodLabel, style: grey),
            pw.Divider(height: 32, color: PdfColors.grey300),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                statCard('Записей', '$total'),
                pw.SizedBox(width: 8),
                statCard('Средний тон', _moodLabel(avgMood)),
                pw.SizedBox(width: 8),
                statCard('Дней с записями', '$daysWithEntries / $totalDays'),
              ],
            ),
            pw.SizedBox(height: 32),

            sectionH('Динамика настроения'),
            if (dayStats.isNotEmpty) ...[
              if (isWeek)
                _buildWeekChart(dayStats, ttf)
              else
                _buildMonthCalendar(dayStats, from, ttf),
              pw.SizedBox(height: 24),
            ] else if (timeline.isNotEmpty) ...[
              _timelineBarChart(timeline, ttf, shortLabels),
              pw.SizedBox(height: 20),
            ],
            if (insights.isNotEmpty) insightBlock(insights),

            // ── Стр. 2: Детали ──
            pw.NewPage(),
            ...detailsPage(),

            pw.SizedBox(height: 32),
            sectionH(
              'Типы дней',
              subtitle: 'Как сильно менялось настроение в течение дня',
            ),
            if (dayTotal > 0) ...[
              barRow(
                'Стабильный',
                stableCount / dayTotal,
                stableColor,
                '$stableCount ${_pluralDays(stableCount)} · '
                    '${_pct(stableCount, dayTotal)}',
              ),
              barRow(
                'Сбалансированный',
                balancedCount / dayTotal,
                balancedColor,
                '$balancedCount ${_pluralDays(balancedCount)} · '
                    '${_pct(balancedCount, dayTotal)}',
              ),
              barRow(
                'Контрастный',
                contrastCount / dayTotal,
                contrastColor,
                '$contrastCount ${_pluralDays(contrastCount)} · '
                    '${_pct(contrastCount, dayTotal)}',
              ),
            ],

            // ── Стр. 3: Корреляции ──
            pw.NewPage(),
            ...corrPage(corrData, corrLabel),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // ─────────────────────────────────────────────────
  // Хелперы PDF-графиков
  // ─────────────────────────────────────────────────

  // Столбчатый bar chart динамики настроения по дням.
  // Положительные значения — зелёный столбец вверх от центра,
  // отрицательные — красный вниз. Ось Y подписана слева.
  pw.Widget _timelineBarChart(
    List<TimePoint> timeline,
    pw.Font ttf,
    bool shortLabels,
  ) {
    const chartH = 75.0;
    const yLabelW = 22.0;
    // Доступная ширина страницы минус поля (40+40) = 515pt, минус Y-ось
    const chartW = 515.0 - yLabelW - 4;
    final n = timeline.length;

    final posColor = _toPdfColor(const Color(0xFF46FF46)); // positiveCalm
    final negColor = _toPdfColor(const Color(0xFFFF5959)); // negativeActive

    final xLabels = timeline.map((p) {
      return shortLabels
          ? DateFormat('EE', 'ru').format(p.time)
          : p.time.day.toString();
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Подписи оси Y: +1 вверху, 0 в центре, -1 внизу
            pw.SizedBox(
              width: yLabelW,
              height: chartH,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '+1',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    ' 0',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    '-1',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 4),
            // Холст графика — PDF координаты: (0,0) в левом нижнем углу
            pw.CustomPaint(
              size: PdfPoint(chartW, chartH),
              painter: (canvas, size) {
                final slotW = size.x / n;
                final barW = slotW * 0.55;
                // Центр по Y — граница нуля
                final centerY = size.y / 2;
                final halfH = centerY - 4;

                // Нулевая линия
                canvas.setColor(PdfColors.grey300);
                canvas.moveTo(0, centerY);
                canvas.lineTo(size.x, centerY);
                canvas.strokePath();

                for (var i = 0; i < n; i++) {
                  final v = timeline[i].value.clamp(-1.0, 1.0);
                  final x = i * slotW + (slotW - barW) / 2;
                  final barH = v.abs() * halfH;
                  if (barH < 0.5) continue;

                  canvas.setColor(v >= 0 ? posColor : negColor);
                  // Положит.: от centerY вверх (y+ = UP в PDF)
                  // Отрицат.: от centerY-barH вверх до centerY
                  canvas.drawRect(
                    x,
                    v >= 0 ? centerY : centerY - barH,
                    barW,
                    barH,
                  );
                  canvas.fillPath();
                }
              },
            ),
          ],
        ),
        // Подписи оси X под графиком
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: yLabelW + 4),
          child: pw.Row(
            children: List.generate(
              n,
              (i) => pw.SizedBox(
                width: chartW / n,
                child: pw.Center(
                  child: pw.Text(
                    xLabels[i],
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 7,
                      color: PdfColors.grey500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Маленький цветной квадрат + подпись для легенды годового графика
  pw.Widget _legendItem(PdfColor color, String label, pw.Font ttf) => pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Container(
        width: 8,
        height: 8,
        decoration: pw.BoxDecoration(color: color),
      ),
      pw.SizedBox(width: 4),
      pw.Text(
        label,
        style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600),
      ),
    ],
  );

  // ─────────────────────────────────────────────────
  // Текстовые хелперы
  // ─────────────────────────────────────────────────

  // Преобразует среднее значение настроения (-1..+1) в читаемый текст
  String _moodLabel(double avg) {
    if (avg >= 0.6) return 'очень позитивный';
    if (avg >= 0.3) return 'позитивный';
    if (avg >= 0.05) return 'умеренно позитивный';
    if (avg >= -0.05) return 'нейтральный';
    if (avg >= -0.3) return 'слегка негативный';
    if (avg >= -0.6) return 'негативный';
    return 'очень негативный';
  }

  // Определяет тип дня по разнообразию квадрантов (логика из AnalyticsService)
  DayType _calcDayType(List<MoodEntryWithMood> dayEntries) {
    if (dayEntries.length <= 1) return DayType.stable;
    final cats = dayEntries.map((e) => e.mood.category).toSet();
    if (cats.length == 1) return DayType.stable;
    final allPositive = cats.every(
      (c) => c == MoodCategory.positiveActive || c == MoodCategory.positiveCalm,
    );
    final allNegative = cats.every(
      (c) => c == MoodCategory.negativeActive || c == MoodCategory.negativeCalm,
    );
    if (allPositive || allNegative) return DayType.balanced;
    return DayType.contrast;
  }

  // Склонение слова «день»
  String _pluralDays(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'дня';
    }
    return 'дней';
  }

  // Склонение слова «запись»
  String _pluralEntries(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'запись';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'записи';
    }
    return 'записей';
  }

  // ─────────────────────────────────────────────────
  // Хелперы
  // ─────────────────────────────────────────────────

  String _categoryLabel(MoodCategory cat) => switch (cat) {
    MoodCategory.positiveActive => 'Активное позитивное',
    MoodCategory.positiveCalm => 'Спокойное позитивное',
    MoodCategory.negativeActive => 'Активное негативное',
    MoodCategory.negativeCalm => 'Спокойное негативное',
  };

  String _pct(int count, int total) =>
      total > 0 ? '${(count / total * 100).toStringAsFixed(1)}%' : '0%';

  // ─────────────────────────────────────────────────
  // PDF: дневной отчёт с тегами и контекстом
  // ─────────────────────────────────────────────────

  Future<List<int>> exportDayToPdfBytes(
    DateTime day, {
    bool trackCycle = false,
  }) async {
    await _ensureExportAccess();

    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final rawEntries = await _repo.getMoodEntriesWithMoodForPeriod(from, to);
    rawEntries.sort((a, b) => a.entry.createdAt.compareTo(b.entry.createdAt));

    // Для каждой записи делаем два отдельных запроса:
    // 1) getContextDetailsForEntry — заметка, путь к фото/голосу
    // 2) getTagsForEntry — список тегов (место, активность, социальный контекст и т.д.)
    // Результаты объединяем в _DayEntry, чтобы дальше работать с одним объектом.
    final entries = <_DayEntry>[];
    for (final e in rawEntries) {
      final details = await _repo.getContextDetailsForEntry(e.entry.id);
      final tags = await _repo.getTagsForEntry(e.entry.id);
      entries.add(_DayEntry(e, details, tags));
    }

    // Данные уровня дня:
    final health = await _repo.getHealthDataForDay(day);
    final dayWeather = rawEntries.isNotEmpty
        ? await _repo.getWeatherForEntry(rawEntries.first.entry.id)
        : null;

    final fontData = await rootBundle.load(
      'lib/ui/assets/fonts/Inter-Regular.ttf',
    );
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    final base = pw.TextStyle(font: ttf, fontSize: 11);
    final h1 = pw.TextStyle(
      font: ttf,
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final h2 = pw.TextStyle(
      font: ttf,
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    final grey = base.copyWith(color: PdfColors.grey600);

    final dayTitle = DateFormat('EEEE, d MMMM yyyy', 'ru').format(day);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: ttf),
        build: (ctx) => [
          pw.Text('Миндаль — твой дневник настроения', style: h1),
          pw.SizedBox(height: 4),
          pw.Text(dayTitle, style: grey),
          pw.Divider(height: 28, color: PdfColors.grey300),

          // Блок контекста дня — рендерим только если хоть что-то есть.
          // Условие health != null || dayWeather != null гарантирует,
          // что пустой блок не появится в PDF.
          if (health != null || dayWeather != null) ...[
            pw.Text('Контекст дня', style: h2),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _buildContextChips(
                health,
                dayWeather,
                ttf,
                trackCycle: trackCycle,
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Список записей
          pw.Text('Записи за день', style: h2),
          pw.SizedBox(height: 8),
          if (entries.isEmpty)
            pw.Text('Записей нет', style: grey)
          else
            ...entries.map((e) => _buildEntryRow(e, ttf, base)),

          pw.SizedBox(height: 20),

          // Итог дня
          pw.Text('Итог дня', style: h2),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.purple50,
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.purple300, width: 3),
              ),
            ),
            child: pw.Text(_buildDayInsight(rawEntries), style: base),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────────────
  // Хелперы дневного PDF
  // ─────────────────────────────────────────────────

  // Конвертация Flutter Color → PdfColor.
  // В новом Flutter API .r/.g/.b уже возвращают double 0.0–1.0 — передаём напрямую.
  PdfColor _toPdfColor(Color c) => PdfColor(c.r, c.g, c.b);

  // Единый чип — белый фон, тёмно-серая рамка. Используется везде.
  pw.Widget _chip(String label, pw.Font ttf) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Text(
      label,
      style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.black),
    ),
  );

  // Собирает список чипов для блока "Контекст дня".
  List<pw.Widget> _buildContextChips(
    HealthDataData? health,
    WeatherDataData? weather,
    pw.Font ttf, {
    bool trackCycle = false,
  }) {
    final chips = <pw.Widget>[];

    if (weather != null) {
      final cloudLabel = switch (weather.cloudiness) {
        Cloudiness.sunny => 'Ясно',
        Cloudiness.cloudy => 'Облачно',
        Cloudiness.overcast => 'Пасмурно',
        null => null,
      };
      if (cloudLabel != null) chips.add(_chip(cloudLabel, ttf));

      final tempStr = weather.rawTemperature != null
          ? '${weather.rawTemperature!.toStringAsFixed(0)}\u00B0C'
          : _tempCatLabel(weather.temperatureCategory);
      chips.add(_chip(tempStr, ttf));

      final precipLabel = switch (weather.precipitation) {
        PrecipitationType.rain => 'Дождь',
        PrecipitationType.snow => 'Снег',
        PrecipitationType.fog => 'Туман',
        PrecipitationType.none || null => null,
      };
      if (precipLabel != null) chips.add(_chip(precipLabel, ttf));
    }

    if (health != null) {
      if (health.sleepMinutes != null) {
        final h = health.sleepMinutes! ~/ 60;
        final m = health.sleepMinutes! % 60;
        final label = m > 0 ? 'Сон: $h ч $m мин' : 'Сон: $h ч';
        chips.add(_chip(label, ttf));
      }
      if (health.stepsAmount != null) {
        final steps = NumberFormat('#,###', 'ru').format(health.stepsAmount);
        chips.add(_chip('Шаги: $steps', ttf));
      }
      if (trackCycle && health.cyclePhase != null) {
        chips.add(_chip(_cycleLabel(health.cyclePhase!), ttf));
      }
    }

    return chips;
  }

  // Рендерит одну запись настроения: время + чип настроения + заметка + теги.
  pw.Widget _buildEntryRow(_DayEntry e, pw.Font ttf, pw.TextStyle base) {
    final time = DateFormat('HH:mm').format(e.item.entry.createdAt);

    final moodColor = _toPdfColor(colorForCategory(e.item.mood.category));
    final note = e.details?.note;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Фиксированная ширина 40 px для времени — выравнивает все записи
              pw.SizedBox(
                width: 40,
                child: pw.Text(
                  time,
                  style: base.copyWith(color: PdfColors.grey500),
                ),
              ),
              pw.SizedBox(width: 8),
              // Чип настроения: белый фон + цветная рамка + черный текст
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: moodColor, width: 1),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  e.item.mood.name,
                  style: base.copyWith(color: PdfColors.black),
                ),
              ),
              // Заметка — только если не пустая; pw.Expanded занимает остаток строки
              if (note != null && note.isNotEmpty) ...[
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    note,
                    style: base.copyWith(color: PdfColors.grey600),
                  ),
                ),
              ],
            ],
          ),

          if (e.tags.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 48),
              child: pw.Wrap(
                spacing: 6,
                runSpacing: 4,
                children: e.tags.map((t) => _chip(t.name, ttf)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Итог дня
  String _buildDayInsight(List<MoodEntryWithMood> entries) {
    if (entries.isEmpty) return 'За этот день записей нет.';

    final positiveCount = entries
        .where(
          (e) =>
              e.mood.category == MoodCategory.positiveActive ||
              e.mood.category == MoodCategory.positiveCalm,
        )
        .length;
    final total = entries.length;
    final pct = (positiveCount / total * 100).round();

    // подсчет самого частого настроеницу
    final moodCounts = <String, int>{};
    for (final e in entries) {
      moodCounts[e.mood.name] = (moodCounts[e.mood.name] ?? 0) + 1;
    }

    final maxValue = moodCounts.values.reduce((a, b) => a > b ? a : b);
    final topMoods = moodCounts.entries
        .where((e) => e.value == maxValue)
        .map((e) => e.key)
        .toList();

    final topMoodText = topMoods.length == 1
        ? topMoods.first
        : '${topMoods.sublist(0, topMoods.length - 1).join(', ')} и ${topMoods.last}';

    if (pct >= 70) {
      return 'Преимущественно позитивный день — $pct% записей с хорошим настроением. Чаще всего: $topMoodText.';
    } else if (pct >= 40) {
      return 'Смешанный день. Позитивных записей $pct%. Самое частое состояние: $topMoodText.';
    } else {
      return 'Сложный день — большинство состояний были негативными. Чаще всего: $topMoodText.';
    }
  }

  String _tempCatLabel(TemperatureCategory cat) => switch (cat) {
    TemperatureCategory.veryCold => 'Очень холодно (\u2264\u221225\u00B0C)',
    TemperatureCategory.cold => 'Холодно (\u221225..\u221210\u00B0C)',
    TemperatureCategory.cool => 'Прохладно (\u221210..+5\u00B0C)',
    TemperatureCategory.comfortable => 'Комфортно (+5..+20\u00B0C)',
    TemperatureCategory.warm => 'Тепло (+20..+30\u00B0C)',
    TemperatureCategory.hot => 'Жарко (\u226530\u00B0C)',
  };

  String _cycleLabel(CyclePhase phase) => switch (phase) {
    CyclePhase.menstruation => 'Менструация',
    CyclePhase.follicular => 'Фолликулярная фаза',
    CyclePhase.ovulation => 'Овуляция',
    CyclePhase.luteal => 'Лютеиновая фаза',
  };

  // ─────────────────────────────────────────────────
  // Графики аналитики для PDF
  // ─────────────────────────────────────────────────

  // ─────────────────────────────────────────────────
  // Scatter-графики корреляций
  // ─────────────────────────────────────────────────

  /// Scatter сон/шаги vs настроение. X=метрика, Y=настроение −1..+1.
  /// Точки окрашены по названию настроения (moodColors).
  pw.Widget _buildScatterChart(
    List<ScatterPoint> points,
    String xUnit,
    pw.Font ttf,
  ) {
    if (points.isEmpty) return pw.SizedBox.shrink();

    const chartH = 100.0;
    const yLabelW = 24.0;
    const chartW = 515.0 - yLabelW - 2.0;

    final xs = points.map((p) => p.x).toList();
    final rawMinX = xs.reduce((a, b) => a < b ? a : b);
    final rawMaxX = xs.reduce((a, b) => a > b ? a : b);
    final xPad = (rawMaxX - rawMinX) < 0.01 ? 1.0 : (rawMaxX - rawMinX) * 0.1;
    final minX = rawMinX - xPad;
    final maxX = rawMaxX + xPad;

    PdfColor dotColor(ScatterPoint p) {
      if (p.moodName != null) {
        final fc = moodColors[p.moodName!];
        if (fc != null) return _toPdfColor(fc);
      }
      if (p.y >= 0.15) return _toPdfColor(const Color(0xFF46FF46));
      if (p.y <= -0.15) return _toPdfColor(const Color(0xFFFF5959));
      return PdfColors.grey500;
    }

    // PDF Y=0 at bottom: mood +1 → y=chartH, mood -1 → y=0
    double yM(double v) => chartH * (v.clamp(-1.0, 1.0) + 1.0) / 2.0;
    double xV(double v) => chartW * (v - minX) / (maxX - minX);

    final labelStyle = pw.TextStyle(
      font: ttf,
      fontSize: 7,
      color: PdfColors.grey500,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: yLabelW,
              height: chartH,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  '+1',
                  '0',
                  '-1',
                ].map((t) => pw.Text(t, style: labelStyle)).toList(),
              ),
            ),
            pw.SizedBox(width: 2),
            pw.CustomPaint(
              size: PdfPoint(chartW, chartH),
              painter: (canvas, size) {
                // Horizontal grid lines
                for (final val in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
                  final y = yM(val);
                  canvas.setColor(
                    val == 0.0 ? PdfColors.grey400 : PdfColors.grey200,
                  );
                  canvas.setLineWidth(val == 0.0 ? 0.7 : 0.4);
                  canvas.moveTo(0, y);
                  canvas.lineTo(chartW, y);
                  canvas.strokePath();
                }
                // Scatter dots
                for (final p in points) {
                  canvas.setColor(dotColor(p));
                  canvas.drawEllipse(xV(p.x), yM(p.y), 3.5, 3.5);
                  canvas.fillPath();
                }
              },
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 26.0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${rawMinX.toStringAsFixed(1)}$xUnit', style: labelStyle),
              pw.Text(
                '${((rawMinX + rawMaxX) / 2).toStringAsFixed(1)}$xUnit',
                style: labelStyle,
              ),
              pw.Text('${rawMaxX.toStringAsFixed(1)}$xUnit', style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }

  /// Scatter погода vs настроение.
  /// X=категория температуры (0-5), Y=настроение −1..+1.
  /// Точки окрашены по moodName; метки X цветные как в приложении.
  pw.Widget _buildWeatherScatterChart(List<ScatterPoint> points, pw.Font ttf) {
    if (points.isEmpty) return pw.SizedBox.shrink();

    const chartH = 100.0;
    const yLabelW = 24.0;
    const chartW = 515.0 - yLabelW - 2.0;

    const catLabels = ['ОХ', 'Хол', 'Пр', 'Ком', 'Теп', 'Жар'];
    final catColors = [
      _toPdfColor(const Color(0xFF89CFF0)),
      _toPdfColor(const Color(0xFF5B9BD5)),
      _toPdfColor(const Color(0xFF7EC8E3)),
      _toPdfColor(const Color(0xFF66FF66)),
      _toPdfColor(const Color(0xFFFFDD3B)),
      _toPdfColor(const Color(0xFFFF5959)),
    ];

    PdfColor dotColor(ScatterPoint p) {
      if (p.moodName != null) {
        final fc = moodColors[p.moodName!];
        if (fc != null) return _toPdfColor(fc);
      }
      return PdfColors.grey500;
    }

    // X: category 0-5 centred evenly
    double xC(double idx) => chartW * idx / 5.0;
    double yM(double v) => chartH * (v.clamp(-1.0, 1.0) + 1.0) / 2.0;

    final labelStyle = pw.TextStyle(
      font: ttf,
      fontSize: 7,
      color: PdfColors.grey500,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: yLabelW,
              height: chartH,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  '+1',
                  '0',
                  '-1',
                ].map((t) => pw.Text(t, style: labelStyle)).toList(),
              ),
            ),
            pw.SizedBox(width: 2),
            pw.CustomPaint(
              size: PdfPoint(chartW, chartH),
              painter: (canvas, size) {
                // Vertical separators per category
                for (var i = 0; i <= 5; i++) {
                  canvas.setColor(PdfColors.grey200);
                  canvas.setLineWidth(0.4);
                  canvas.moveTo(xC(i.toDouble()), 0);
                  canvas.lineTo(xC(i.toDouble()), chartH);
                  canvas.strokePath();
                }
                // Horizontal grid
                for (final val in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
                  final y = yM(val);
                  canvas.setColor(
                    val == 0.0 ? PdfColors.grey400 : PdfColors.grey200,
                  );
                  canvas.setLineWidth(val == 0.0 ? 0.7 : 0.4);
                  canvas.moveTo(0, y);
                  canvas.lineTo(chartW, y);
                  canvas.strokePath();
                }
                // Scatter dots
                for (final p in points) {
                  canvas.setColor(dotColor(p));
                  canvas.drawEllipse(xC(p.x), yM(p.y), 3.5, 3.5);
                  canvas.fillPath();
                }
              },
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 26.0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (i) => pw.Text(
                catLabels[i],
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 8,
                  color: catColors[i],
                ),
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        // Weather category legend: abbreviation → full name + temperature range
        pw.Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _legendItem(catColors[0], 'ОХ — очень холодно (≤ −25°C)', ttf),
            _legendItem(catColors[1], 'Хол — холодно (−25…−10°C)', ttf),
            _legendItem(catColors[2], 'Пр — прохладно (−10…+5°C)', ttf),
            _legendItem(catColors[3], 'Ком — комфортно (+5…+20°C)', ttf),
            _legendItem(catColors[4], 'Теп — тепло (+20…+30°C)', ttf),
            _legendItem(catColors[5], 'Жар — жарко (≥ +30°C)', ttf),
          ],
        ),
      ],
    );
  }

  /// Scatter цикл vs настроение.
  /// X=настроение −1..+1, Y=фаза 0..3 (М внизу, Л вверху).
  /// Точки окрашены по названию настроения; лейблы фаз на оси Y цветные.
  pw.Widget _buildCycleScatterChart(List<ScatterPoint> points, pw.Font ttf) {
    if (points.isEmpty) return pw.SizedBox.shrink();

    const chartH = 120.0; // чуть выше чтобы 4 строки читались
    const yLabelW = 28.0; // шире для буквы + отступ
    const chartW = 515.0 - yLabelW - 2.0;

    // Цвета фаз захардкожены напрямую в PdfColor (0.0–1.0)
    // М=0 Ф=1 О=2 Л=3
    final phaseColors = [
      PdfColor(1.0, 0.4745, 0.4745), // FF7979 — М красный
      PdfColor(0.4, 1.0, 0.4), // 66FF66 — Ф зелёный
      PdfColor(1.0, 0.9216, 0.5373), // FFEB89 — О жёлтый
      PdfColor(0.7216, 0.6314, 1.0), // B8A1FF — Л фиолетовый
    ];
    const phaseLabels = ['М', 'Ф', 'О', 'Л'];

    // Точки — цвет по настроению
    PdfColor dotColor(ScatterPoint p) {
      if (p.moodName != null) {
        final fc = moodColors[p.moodName!];
        if (fc != null) return _toPdfColor(fc);
      }
      if (p.y >= 0.15) return PdfColor(0.4, 1.0, 0.4);
      if (p.y <= -0.15) return PdfColor(1.0, 0.349, 0.349);
      return PdfColors.grey500;
    }

    // X: настроение -1..+1 → 0..chartW
    double xM(double v) => chartW * (v.clamp(-1.0, 1.0) + 1.0) / 2.0;
    // Y: фаза 0(М)=низ, 3(Л)=верх → PDF Y=0 снизу
    double yP(double idx) => chartH * idx / 3.0;

    final labelStyle = pw.TextStyle(
      font: ttf,
      fontSize: 7,
      color: PdfColors.grey500,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Y axis: Л вверху … М внизу, каждая буква своим цветом
            pw.SizedBox(
              width: yLabelW,
              height: chartH,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: List.generate(4, (i) {
                  final idx = 3 - i; // i=0 → Л(top), i=3 → М(bottom)
                  return pw.Text(
                    phaseLabels[idx],
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      color: phaseColors[idx],
                    ),
                  );
                }),
              ),
            ),
            pw.SizedBox(width: 2),
            pw.CustomPaint(
              size: PdfPoint(chartW, chartH),
              painter: (canvas, size) {
                // Горизонтальные линии на уровне каждой фазы
                for (var i = 0; i <= 3; i++) {
                  final y = yP(i.toDouble());
                  canvas.setColor(PdfColors.grey200);
                  canvas.setLineWidth(0.5);
                  canvas.moveTo(0, y);
                  canvas.lineTo(chartW, y);
                  canvas.strokePath();
                }
                // Вертикальная нулевая линия (настроение = 0)
                canvas.setColor(PdfColors.grey400);
                canvas.setLineWidth(0.7);
                canvas.moveTo(xM(0), 0);
                canvas.lineTo(xM(0), chartH);
                canvas.strokePath();
                // Точки
                for (final p in points) {
                  canvas.setColor(dotColor(p));
                  canvas.drawEllipse(xM(p.x), yP(p.y), 3.5, 3.5);
                  canvas.fillPath();
                }
              },
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        // X axis: −1, 0, +1
        pw.Padding(
          padding: pw.EdgeInsets.only(left: yLabelW + 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('−1', style: labelStyle),
              pw.Text('0', style: labelStyle),
              pw.Text('+1', style: labelStyle),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // Легенда: только текст, без цветных квадратов
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Text(
                  'М — Менструальная',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  'Ф — Фолликулярная',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text(
                  'О — Овуляция',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  'Л — Лютеиновая',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Индекс фазы цикла (0=М, 1=Ф, 2=О, 3=Л) для оси Y scatter.
  int _cyclePhaseIndex(CyclePhase phase) => switch (phase) {
    CyclePhase.menstruation => 0,
    CyclePhase.follicular => 1,
    CyclePhase.ovulation => 2,
    CyclePhase.luteal => 3,
  };

  /// Индекс категории температуры (0=очень холодно … 5=жарко) для оси X.
  int _tempCatIdx(TemperatureCategory cat) => switch (cat) {
    TemperatureCategory.veryCold => 0,
    TemperatureCategory.cold => 1,
    TemperatureCategory.cool => 2,
    TemperatureCategory.comfortable => 3,
    TemperatureCategory.warm => 4,
    TemperatureCategory.hot => 5,
  };

  /// Линейный график недели (Пн–Вс): серая линия + цветные точки по типу дня.
  pw.Widget _buildWeekChart(List<DayStats> dayStats, pw.Font ttf) {
    const chartH = 80.0;
    const yLabelW = 22.0;
    const chartW = 515.0 - yLabelW - 2.0;

    final byWd = <int, DayStats>{for (final d in dayStats) d.date.weekday: d};

    PdfColor dtColor(DayType t) => switch (t) {
      DayType.stable => _toPdfColor(const Color(0xFF7EC8E3)),
      DayType.balanced => _toPdfColor(const Color(0xFFB8A9E3)),
      DayType.contrast => _toPdfColor(const Color(0xFFF4A261)),
    };

    // Y=0 at bottom in PDF canvas: val=+1 → y=chartH (top), val=-1 → y=0 (bottom)
    double yM(double v) => chartH * (v.clamp(-1.0, 1.0) + 1.0) / 2.0;
    // Equal spacing across 7 slots: wd 1..7 maps to x 0..chartW
    double xW(int wd) => (wd - 1) * chartW / 6.0;

    final labelStyle = pw.TextStyle(
      font: ttf,
      fontSize: 7,
      color: PdfColors.grey500,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Y-axis labels
            pw.SizedBox(
              width: yLabelW,
              height: chartH,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  '+1',
                  '0',
                  '-1',
                ].map((t) => pw.Text(t, style: labelStyle)).toList(),
              ),
            ),
            pw.SizedBox(width: 2),
            pw.CustomPaint(
              size: PdfPoint(chartW, chartH),
              painter: (canvas, size) {
                // Horizontal grid lines
                for (final val in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
                  final y = yM(val);
                  canvas.setColor(
                    val == 0.0 ? PdfColors.grey400 : PdfColors.grey200,
                  );
                  canvas.setLineWidth(val == 0.0 ? 0.7 : 0.4);
                  canvas.moveTo(0, y);
                  canvas.lineTo(chartW, y);
                  canvas.strokePath();
                }

                // Collect ordered data points
                final xs = <double>[];
                final ys = <double>[];
                for (var wd = 1; wd <= 7; wd++) {
                  final ds = byWd[wd];
                  if (ds != null) {
                    xs.add(xW(wd));
                    ys.add(yM(ds.avgMood));
                  }
                }

                // Connecting line
                if (xs.length >= 2) {
                  canvas.setColor(PdfColors.grey400);
                  canvas.setLineWidth(1.5);
                  for (var i = 0; i < xs.length - 1; i++) {
                    canvas.moveTo(xs[i], ys[i]);
                    canvas.lineTo(xs[i + 1], ys[i + 1]);
                    canvas.strokePath();
                  }
                }

                // Colored dots by day type, drawn on top of line
                for (var wd = 1; wd <= 7; wd++) {
                  final ds = byWd[wd];
                  if (ds == null) continue;
                  canvas.setColor(dtColor(ds.dayType));
                  canvas.drawEllipse(xW(wd), yM(ds.avgMood), 5.0, 5.0);
                  canvas.fillPath();
                }
              },
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        // X-axis day labels
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 24.0),
          child: pw.Row(
            children: List.generate(
              7,
              (i) => pw.SizedBox(
                width: chartW / 7,
                child: pw.Center(
                  child: pw.Text(
                    ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i],
                    style: labelStyle,
                  ),
                ),
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        _buildDayTypeLegend(ttf),
      ],
    );
  }

  /// Календарная сетка месяца: кружок на каждый день, цвет по типу дня.
  pw.Widget _buildMonthCalendar(
    List<DayStats> dayStats,
    DateTime month,
    pw.Font ttf,
  ) {
    final byDay = <int, DayStats>{for (final ds in dayStats) ds.date.day: ds};
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = firstDay.weekday - 1; // 0 = Monday

    PdfColor dtColor(DayType t) => switch (t) {
      DayType.stable => _toPdfColor(const Color(0xFF7EC8E3)),
      DayType.balanced => _toPdfColor(const Color(0xFFB8A9E3)),
      DayType.contrast => _toPdfColor(const Color(0xFFF4A261)),
    };

    // Blend color with white at given opacity (simulates semi-transparency on white)
    PdfColor tint(PdfColor c, double opacity) => PdfColor(
      c.red * opacity + (1 - opacity),
      c.green * opacity + (1 - opacity),
      c.blue * opacity + (1 - opacity),
    );

    const cellSize = 22.0;
    const cellPad = 5.0;

    final hStyle = pw.TextStyle(
      font: ttf,
      fontSize: 8,
      color: PdfColors.grey600,
    );
    const headers = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    pw.Widget dayCell(int? dayNum) {
      if (dayNum == null) {
        return pw.Expanded(child: pw.SizedBox(height: cellSize));
      }
      final ds = byDay[dayNum];
      final borderColor = ds != null ? dtColor(ds.dayType) : PdfColors.grey200;
      final bgColor = ds != null ? tint(borderColor, 0.18) : PdfColors.grey100;
      final textColor = ds != null ? PdfColors.black : PdfColors.grey400;

      return pw.Expanded(
        child: pw.Center(
          child: pw.Container(
            width: cellSize,
            height: cellSize,
            decoration: pw.BoxDecoration(
              color: bgColor,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: borderColor, width: 1.0),
            ),
            child: pw.Center(
              child: pw.Text(
                '$dayNum',
                style: pw.TextStyle(font: ttf, fontSize: 7, color: textColor),
              ),
            ),
          ),
        ),
      );
    }

    final totalCells = offset + daysInMonth;
    final rows = <pw.Widget>[];

    // Header row
    rows.add(
      pw.Row(
        children: headers
            .map(
              (h) => pw.Expanded(
                child: pw.Center(child: pw.Text(h, style: hStyle)),
              ),
            )
            .toList(),
      ),
    );
    rows.add(pw.SizedBox(height: 6));

    // Day rows
    for (var row = 0; row * 7 < totalCells; row++) {
      final cells = <pw.Widget>[];
      for (var col = 0; col < 7; col++) {
        final idx = row * 7 + col;
        if (idx < offset || idx >= offset + daysInMonth) {
          cells.add(pw.Expanded(child: pw.SizedBox(height: cellSize)));
        } else {
          cells.add(dayCell(idx - offset + 1));
        }
      }
      rows.add(pw.Row(children: cells));
      rows.add(pw.SizedBox(height: cellPad));
    }

    rows.add(pw.SizedBox(height: 10));
    rows.add(_buildDayTypeLegend(ttf));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rows,
    );
  }

  /// Легенда типов дней: три квадрата с подписями.
  pw.Widget _buildDayTypeLegend(pw.Font ttf) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
    ),
    child: pw.Row(
      children: [
        _legendItem(_toPdfColor(const Color(0xFF7EC8E3)), 'Стабильный', ttf),
        pw.SizedBox(width: 12),
        _legendItem(
          _toPdfColor(const Color(0xFFB8A9E3)),
          'Сбалансированный',
          ttf,
        ),
        pw.SizedBox(width: 12),
        _legendItem(_toPdfColor(const Color(0xFFF4A261)), 'Контрастный', ttf),
      ],
    ),
  );

  /// Горизонтальные бары квадрантов, сгруппированные по знаку (воспроизводит QuadrantBreakdown).
  pw.Widget _buildQuadrantBars(Map<MoodCategory, int> counts, pw.Font ttf) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return pw.SizedBox.shrink();

    const barMaxW = 200.0;
    const barH = 7.0;

    pw.Widget bar(MoodCategory cat, String label) {
      final count = counts[cat] ?? 0;
      final pct = count / total;
      final color = _toPdfColor(colorForCategory(cat));
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 110,
              child: pw.Text(
                label,
                style: pw.TextStyle(font: ttf, fontSize: 9, color: color),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Stack(
              children: [
                pw.Container(
                  width: barMaxW,
                  height: barH,
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                ),
                if (pct > 0)
                  pw.Container(
                    width: barMaxW * pct.clamp(0.0, 1.0),
                    height: barH,
                    decoration: pw.BoxDecoration(color: color),
                  ),
              ],
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '${(pct * 100).round()}%',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      );
    }

    final groupLabel = pw.TextStyle(
      font: ttf,
      fontSize: 11,
      color: PdfColors.grey700,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Позитивное:', style: groupLabel),
        pw.SizedBox(height: 6),
        bar(MoodCategory.positiveActive, 'Высокая энергия'),
        bar(MoodCategory.positiveCalm, 'Низкая энергия'),
        pw.SizedBox(height: 10),
        pw.Text('Негативное:', style: groupLabel),
        pw.SizedBox(height: 6),
        bar(MoodCategory.negativeActive, 'Высокая энергия'),
        bar(MoodCategory.negativeCalm, 'Низкая энергия'),
      ],
    );
  }
}
