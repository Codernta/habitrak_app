import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../habit/domain/entities/habit.dart';
import '../../../../core/services/analytics_service.dart';

class ProgressReportPdfService {
  static final ProgressReportPdfService _instance =
      ProgressReportPdfService._internal();
  factory ProgressReportPdfService() => _instance;
  ProgressReportPdfService._internal();

  /// Formats date for display e.g. "Nov 23, 2026 • 5:02 PM"
  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour:$minute $period';
  }

  /// Formats a clean date string e.g. "November 23, 2026"
  String _formatDate(DateTime dt) {
    const fullMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${fullMonths[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Generates the complete PDF document bytes using the latest Neo-Health Bento design
  Future<Uint8List> generateProgressReportPdf({
    required String userName,
    required int streakDays,
    required int totalMindfulMinutes,
    required List<Habit> habits,
    required List<Map<String, dynamic>> habitHistory,
    required List<Map<String, dynamic>> reflections,
    required List<Map<String, dynamic>> goals,
    required List<Map<String, dynamic>> activities,
    required String integritySha256,
  }) async {
    final pdf = pw.Document(
      title: 'Habitrak Personal Progress Report',
      author: 'Habitrak',
      creator: 'Habitrak Neo-Health Engine',
      subject: 'Neo-Health Habit & Progress Analytics',
    );

    AnalyticsService().logProgressReportGenerated(
      streakDays: streakDays,
      mindfulMinutes: totalMindfulMinutes,
      totalCompletedHabits: habits.where((h) => h.isCompleted).length,
    );

    // Load fonts gracefully with fallback
    pw.Font baseFont;
    pw.Font boldFont;
    try {
      baseFont = await PdfGoogleFonts.hankenGroteskRegular();
      boldFont = await PdfGoogleFonts.hankenGroteskBold();
    } catch (e) {
      debugPrint('Google Fonts loading failed, using standard Helvetica: $e');
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    // Load app logo
    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/images/logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Could not load logo for PDF: $e');
    }

    final now = DateTime.now();
    final exportDateStr = _formatDateTime(now);
    final headerDateStr = _formatDate(now);

    // --- NEO-HEALTH BENTO PALETTE ---
    final obsidianBlack = PdfColor.fromHex('#16181A'); // Primary dark surface

    // Electric Lime (Chartreuse) - Signature Brand Pop
    final electricLime = PdfColor.fromHex('#D2EB70');
    final limeLight = PdfColor.fromHex('#F4FBE0');
    final limeDark = PdfColor.fromHex('#2A3614');

    // Lavender / Periwinkle - Signature Secondary
    final lavenderAccent = PdfColor.fromHex('#B6B8F8');
    final lavenderLight = PdfColor.fromHex('#E8E9FD');
    final lavenderDark = PdfColor.fromHex('#6A6DD8');

    // Soft Rose - Tertiary Accent
    final roseLight = PdfColor.fromHex('#FCE8EC');
    final roseDark = PdfColor.fromHex('#8C293E');

    // Clean Bento Neutrals
    final surfaceWhite = PdfColor.fromHex('#FFFFFF');
    final zebraLight = PdfColor.fromHex('#F8F9FA');
    final outlineBorder = PdfColor.fromHex('#E2E4E8');
    final textMuted = PdfColor.fromHex('#72767E');
    final textOnDarkMuted = PdfColor.fromHex('#9DA2AA');

    // Summary calculations
    final totalHabits = habits.length;
    final completedHabits = habits.where((h) => h.isCompleted).length;
    final completionRate =
        totalHabits > 0 ? ((completedHabits / totalHabits) * 100).round() : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoBytes != null)
                      pw.Container(
                        width: 26,
                        height: 26,
                        margin: const pw.EdgeInsets.only(right: 8),
                        decoration: pw.BoxDecoration(
                          color: lavenderLight,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Image(pw.MemoryImage(logoBytes)),
                      ),
                    pw.Text(
                      'HABITRAK',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        color: obsidianBlack,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: pw.BoxDecoration(
                        color: electricLime,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'NEO-HEALTH REPORT',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 7.5,
                          color: obsidianBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: lavenderLight,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    headerDateStr,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8,
                      color: lavenderDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                  top: pw.BorderSide(color: outlineBorder, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 5,
                          height: 5,
                          decoration: pw.BoxDecoration(
                            color: electricLime,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'Habitrak Neo-Health Engine v1.0.0 • On-Device Cryptographic Verification',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 7.5,
                            color: obsidianBlack,
                          ),
                        ),
                      ],
                    ),
                    if (integritySha256.isNotEmpty)
                      pw.Text(
                        'SHA-256: ${integritySha256.length > 32 ? "${integritySha256.substring(0, 32)}..." : integritySha256}',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 7,
                          color: textMuted,
                        ),
                      ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: zebraLight,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: outlineBorder, width: 0.5),
                  ),
                  child: pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 7.5,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Top Hero Bento Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: obsidianBlack,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Personal Progress & Wellness Report',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 16,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Neo-Health Habit Tracking • Prepared for $userName',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 9.5,
                          color: textOnDarkMuted,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: electricLime,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      exportDateStr,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: obsidianBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 4 Executive Bento KPI Cards
            pw.Row(
              children: [
                _buildBentoKpiCard(
                  title: 'Active Habits',
                  value: '$totalHabits',
                  subtitle: '$completedHabits Completed Today',
                  boldFont: boldFont,
                  baseFont: baseFont,
                  surfaceWhite: surfaceWhite,
                  outlineBorder: outlineBorder,
                  valueColor: obsidianBlack,
                  accentColor: electricLime,
                ),
                pw.SizedBox(width: 8),
                _buildBentoKpiCard(
                  title: "Today's Rate",
                  value: '$completionRate%',
                  subtitle: '$completedHabits of $totalHabits Finished',
                  boldFont: boldFont,
                  baseFont: baseFont,
                  surfaceWhite: surfaceWhite,
                  outlineBorder: outlineBorder,
                  valueColor: obsidianBlack,
                  accentColor: electricLime,
                  isPillAccent: true,
                  pillText: '$completedHabits / $totalHabits',
                  electricLime: electricLime,
                  obsidianBlack: obsidianBlack,
                ),
                pw.SizedBox(width: 8),
                _buildBentoKpiCard(
                  title: 'Current Streak',
                  value: '$streakDays Days',
                  subtitle: 'Continuous Flow',
                  boldFont: boldFont,
                  baseFont: baseFont,
                  surfaceWhite: surfaceWhite,
                  outlineBorder: outlineBorder,
                  valueColor: lavenderDark,
                  accentColor: lavenderAccent,
                ),
                pw.SizedBox(width: 8),
                _buildBentoKpiCard(
                  title: 'Mindful Minutes',
                  value: '$totalMindfulMinutes min',
                  subtitle: 'Total Awareness',
                  boldFont: boldFont,
                  baseFont: baseFont,
                  surfaceWhite: surfaceWhite,
                  outlineBorder: outlineBorder,
                  valueColor: obsidianBlack,
                  accentColor: lavenderDark,
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // SECTION 1: HABITS TABLE (BENTO STYLE)
            _buildBentoSectionHeader(
              title: 'Current Habits & Daily Progress',
              boldFont: boldFont,
              obsidianBlack: obsidianBlack,
              countText: '$totalHabits Tracked',
              electricLime: electricLime,
            ),
            pw.SizedBox(height: 8),
            _buildHabitsTable(
              habits: habits,
              boldFont: boldFont,
              baseFont: baseFont,
              obsidianBlack: obsidianBlack,
              outlineBorder: outlineBorder,
              zebraLight: zebraLight,
              electricLime: electricLime,
              limeLight: limeLight,
              limeDark: limeDark,
              lavenderAccent: lavenderAccent,
              lavenderLight: lavenderLight,
              lavenderDark: lavenderDark,
              roseLight: roseLight,
              roseDark: roseDark,
            ),
            pw.SizedBox(height: 16),

            // SECTION 2: CONSISTENCY HISTORY
            _buildBentoSectionHeader(
              title: 'Consistency & History Log',
              boldFont: boldFont,
              obsidianBlack: obsidianBlack,
              countText: '${habitHistory.length} Days Recorded',
              electricLime: lavenderAccent,
            ),
            pw.SizedBox(height: 8),
            if (habitHistory.isNotEmpty)
              _buildHistoryTable(
                habitHistory: habitHistory,
                boldFont: boldFont,
                baseFont: baseFont,
                obsidianBlack: obsidianBlack,
                outlineBorder: outlineBorder,
                zebraLight: zebraLight,
                electricLime: electricLime,
                limeLight: limeLight,
                limeDark: limeDark,
              )
            else
              _buildEmptyStateBox(
                message:
                    'Daily consistency logs are automatically captured as you complete habits throughout the week.',
                baseFont: baseFont,
                surfaceWhite: surfaceWhite,
                outlineBorder: outlineBorder,
              ),
            pw.SizedBox(height: 16),

            // SECTION 3: MINDFUL REFLECTIONS
            _buildBentoSectionHeader(
              title: 'Mindful Reflections & Journal Entries',
              boldFont: boldFont,
              obsidianBlack: obsidianBlack,
              countText: '${reflections.length} Entries',
              electricLime: lavenderAccent,
            ),
            pw.SizedBox(height: 8),
            if (reflections.isNotEmpty)
              _buildReflectionsTable(
                reflections: reflections,
                boldFont: boldFont,
                baseFont: baseFont,
                obsidianBlack: obsidianBlack,
                outlineBorder: outlineBorder,
                zebraLight: zebraLight,
                lavenderLight: lavenderLight,
                lavenderDark: lavenderDark,
              )
            else
              _buildEmptyStateBox(
                message:
                    'No reflections recorded yet. Capture mindful thoughts in the Mindfulness tab.',
                baseFont: baseFont,
                surfaceWhite: surfaceWhite,
                outlineBorder: outlineBorder,
              ),
            pw.SizedBox(height: 16),

            // SECTION 4: GOALS & ACTIVITIES
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Intentional Goals (Left Column)
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildBentoSectionHeader(
                        title: 'Intentional Daily Goals',
                        boldFont: boldFont,
                        obsidianBlack: obsidianBlack,
                        countText: '${goals.length} Goals',
                        electricLime: electricLime,
                      ),
                      pw.SizedBox(height: 8),
                      if (goals.isNotEmpty)
                        _buildGoalsTable(
                          goals: goals,
                          boldFont: boldFont,
                          baseFont: baseFont,
                          obsidianBlack: obsidianBlack,
                          outlineBorder: outlineBorder,
                          zebraLight: zebraLight,
                          electricLime: electricLime,
                          limeLight: limeLight,
                          limeDark: limeDark,
                          lavenderLight: lavenderLight,
                          lavenderDark: lavenderDark,
                        )
                      else
                        _buildEmptyStateBox(
                          message: 'No intentional goals set.',
                          baseFont: baseFont,
                          surfaceWhite: surfaceWhite,
                          outlineBorder: outlineBorder,
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                // Activity & Movement Logs (Right Column)
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildBentoSectionHeader(
                        title: 'Tracked Activities & Workouts',
                        boldFont: boldFont,
                        obsidianBlack: obsidianBlack,
                        countText: '${activities.length} Logs',
                        electricLime: lavenderAccent,
                      ),
                      pw.SizedBox(height: 8),
                      if (activities.isNotEmpty)
                        _buildActivitiesTable(
                          activities: activities,
                          boldFont: boldFont,
                          baseFont: baseFont,
                          obsidianBlack: obsidianBlack,
                          outlineBorder: outlineBorder,
                          zebraLight: zebraLight,
                          lavenderLight: lavenderLight,
                          lavenderDark: lavenderDark,
                        )
                      else
                        _buildEmptyStateBox(
                          message:
                              'No workout logs recorded yet. Track walks and yoga sessions in Activity.',
                          baseFont: baseFont,
                          surfaceWhite: surfaceWhite,
                          outlineBorder: outlineBorder,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- BENTO WIDGET BUILDERS ---

  pw.Widget _buildBentoKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor surfaceWhite,
    required PdfColor outlineBorder,
    required PdfColor valueColor,
    required PdfColor accentColor,
    bool isPillAccent = false,
    String? pillText,
    PdfColor? electricLime,
    PdfColor? obsidianBlack,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: pw.BoxDecoration(
          color: surfaceWhite,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: outlineBorder, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 7.5,
                    color: PdfColor.fromHex('#72767E'),
                    letterSpacing: 0.5,
                  ),
                ),
                if (isPillAccent && pillText != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1.5),
                    decoration: pw.BoxDecoration(
                      color: electricLime,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      pillText,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 6.5,
                        color: obsidianBlack,
                      ),
                    ),
                  )
                else
                  pw.Container(
                    width: 5,
                    height: 5,
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 15,
                color: valueColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                font: baseFont,
                fontSize: 7.5,
                color: PdfColor.fromHex('#72767E'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBentoSectionHeader({
    required String title,
    required pw.Font boldFont,
    required PdfColor obsidianBlack,
    String? countText,
    required PdfColor electricLime,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 12,
              margin: const pw.EdgeInsets.only(right: 6),
              decoration: pw.BoxDecoration(
                color: electricLime,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.Text(
              title,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 12,
                color: obsidianBlack,
              ),
            ),
          ],
        ),
        if (countText != null)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4FBE0'),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: electricLime, width: 0.5),
            ),
            child: pw.Text(
              countText,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 7.5,
                color: PdfColor.fromHex('#2A3614'),
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildHabitsTable({
    required List<Habit> habits,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor obsidianBlack,
    required PdfColor outlineBorder,
    required PdfColor zebraLight,
    required PdfColor electricLime,
    required PdfColor limeLight,
    required PdfColor limeDark,
    required PdfColor lavenderAccent,
    required PdfColor lavenderLight,
    required PdfColor lavenderDark,
    required PdfColor roseLight,
    required PdfColor roseDark,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: outlineBorder, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(22), // #
          1: pw.FlexColumnWidth(3.0), // Title
          2: pw.FlexColumnWidth(1.8), // Category
          3: pw.FlexColumnWidth(1.6), // Target
          4: pw.FlexColumnWidth(2.0), // Progress
          5: pw.FlexColumnWidth(1.3), // Streak
          6: pw.FlexColumnWidth(1.8), // Status
        },
        children: [
          // Header Row
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: obsidianBlack,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            children: [
              _buildTableHeaderCell('#', boldFont),
              _buildTableHeaderCell('Habit Name', boldFont),
              _buildTableHeaderCell('Category', boldFont),
              _buildTableHeaderCell('Daily Target', boldFont),
              _buildTableHeaderCell('Current Progress', boldFont),
              _buildTableHeaderCell('Streak', boldFont),
              _buildTableHeaderCell('Status', boldFont),
            ],
          ),
          // Body Rows
          for (int i = 0; i < habits.length; i++) ...[
            _buildHabitRow(
              index: i + 1,
              habit: habits[i],
              isEven: i % 2 == 0,
              boldFont: boldFont,
              baseFont: baseFont,
              zebraLight: zebraLight,
              outlineBorder: outlineBorder,
              electricLime: electricLime,
              limeLight: limeLight,
              limeDark: limeDark,
              lavenderLight: lavenderLight,
              lavenderDark: lavenderDark,
              roseLight: roseLight,
              roseDark: roseDark,
              obsidianBlack: obsidianBlack,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String text, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 8,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.TableRow _buildHabitRow({
    required int index,
    required Habit habit,
    required bool isEven,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor zebraLight,
    required PdfColor outlineBorder,
    required PdfColor electricLime,
    required PdfColor limeLight,
    required PdfColor limeDark,
    required PdfColor lavenderLight,
    required PdfColor lavenderDark,
    required PdfColor roseLight,
    required PdfColor roseDark,
    required PdfColor obsidianBlack,
  }) {
    // Target display string
    final targetStr = habit.unit.isNotEmpty
        ? '${habit.targetProgress % 1 == 0 ? habit.targetProgress.toInt() : habit.targetProgress.toStringAsFixed(1)} ${habit.unit}'
        : '${habit.targetProgress % 1 == 0 ? habit.targetProgress.toInt() : habit.targetProgress.toStringAsFixed(1)} target';

    // Progress display string
    final currentStr = habit.unit.isNotEmpty
        ? '${habit.currentProgress % 1 == 0 ? habit.currentProgress.toInt() : habit.currentProgress.toStringAsFixed(1)} ${habit.unit}'
        : '${habit.currentProgress % 1 == 0 ? habit.currentProgress.toInt() : habit.currentProgress.toStringAsFixed(1)}';

    final percent = habit.targetProgress > 0
        ? ((habit.currentProgress / habit.targetProgress) * 100).clamp(0, 100).round()
        : (habit.isCompleted ? 100 : 0);

    // Category styling (Neo-Health)
    PdfColor catBg;
    PdfColor catColor;
    switch (habit.category) {
      case HabitCategory.health:
        catBg = limeLight;
        catColor = limeDark;
        break;
      case HabitCategory.mindfulness:
        catBg = lavenderLight;
        catColor = lavenderDark;
        break;
      case HabitCategory.growth:
        catBg = roseLight;
        catColor = roseDark;
        break;
    }

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven ? PdfColors.white : zebraLight,
        border: pw.Border(
          bottom: pw.BorderSide(color: outlineBorder, width: 0.5),
        ),
      ),
      children: [
        // #
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          alignment: pw.Alignment.center,
          child: pw.Text(
            '$index',
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 7.5,
              color: PdfColor.fromHex('#9DA2AA'),
            ),
          ),
        ),
        // Title
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                habit.title,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 8.5,
                  color: obsidianBlack,
                ),
              ),
              if (habit.scheduledTime != null &&
                  habit.scheduledTime!.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'Scheduled: ${habit.scheduledTime}',
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 6.5,
                    color: PdfColor.fromHex('#72767E'),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Category
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: catBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              habit.category.displayName,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 6.5,
                color: catColor,
              ),
            ),
          ),
        ),
        // Target
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            targetStr,
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 8,
              color: PdfColor.fromHex('#52575F'),
            ),
          ),
        ),
        // Current Progress
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            '$currentStr ($percent%)',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
              color: habit.isCompleted ? limeDark : obsidianBlack,
            ),
          ),
        ),
        // Streak
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            '${habit.streak} d',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
              color: obsidianBlack,
            ),
          ),
        ),
        // Status Pill (Neo-Health: Electric Lime for Completed, Lavender for In Progress)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: pw.BoxDecoration(
              color: habit.isCompleted ? electricLime : lavenderLight,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              habit.isCompleted ? 'Completed' : 'In Progress',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 6.5,
                color: habit.isCompleted ? obsidianBlack : lavenderDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHistoryTable({
    required List<Map<String, dynamic>> habitHistory,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor obsidianBlack,
    required PdfColor outlineBorder,
    required PdfColor zebraLight,
    required PdfColor electricLime,
    required PdfColor limeLight,
    required PdfColor limeDark,
  }) {
    final displayHistory = habitHistory.take(7).toList();

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: outlineBorder, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(2.5), // Date
          1: pw.FlexColumnWidth(2.0), // Completed Count
          2: pw.FlexColumnWidth(2.0), // Total Habits
          3: pw.FlexColumnWidth(2.0), // Success Rate
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: obsidianBlack,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            children: [
              _buildTableHeaderCell('Date', boldFont),
              _buildTableHeaderCell('Completed Habits', boldFont),
              _buildTableHeaderCell('Total Habits', boldFont),
              _buildTableHeaderCell('Daily Consistency', boldFont),
            ],
          ),
          for (int i = 0; i < displayHistory.length; i++) ...[
            _buildHistoryRow(
              entry: displayHistory[i],
              isEven: i % 2 == 0,
              boldFont: boldFont,
              baseFont: baseFont,
              zebraLight: zebraLight,
              outlineBorder: outlineBorder,
              electricLime: electricLime,
              limeDark: limeDark,
              obsidianBlack: obsidianBlack,
            ),
          ],
        ],
      ),
    );
  }

  pw.TableRow _buildHistoryRow({
    required Map<String, dynamic> entry,
    required bool isEven,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor zebraLight,
    required PdfColor outlineBorder,
    required PdfColor electricLime,
    required PdfColor limeDark,
    required PdfColor obsidianBlack,
  }) {
    final dateStr = entry['date']?.toString() ?? 'Recent';
    final completed = entry['completedCount'] as int? ?? 0;
    final total = entry['totalHabits'] as int? ?? 0;
    final rate = total > 0 ? ((completed / total) * 100).round() : 0;

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven ? PdfColors.white : zebraLight,
        border: pw.Border(
          bottom: pw.BorderSide(color: outlineBorder, width: 0.5),
        ),
      ),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            dateStr,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
              color: obsidianBlack,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            '$completed habits',
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 8,
              color: PdfColor.fromHex('#52575F'),
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            '$total total',
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 8,
              color: PdfColor.fromHex('#52575F'),
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: pw.BoxDecoration(
              color: electricLime,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              '$rate% success',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 6.5,
                color: obsidianBlack,
              ),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReflectionsTable({
    required List<Map<String, dynamic>> reflections,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor obsidianBlack,
    required PdfColor outlineBorder,
    required PdfColor zebraLight,
    required PdfColor lavenderLight,
    required PdfColor lavenderDark,
  }) {
    final displayRefs = reflections.take(5).toList();

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: outlineBorder, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(2.2), // Date
          1: pw.FlexColumnWidth(7.8), // Reflection Text
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: obsidianBlack,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            children: [
              _buildTableHeaderCell('Date / Timeline', boldFont),
              _buildTableHeaderCell('Mindful Reflection Note', boldFont),
            ],
          ),
          for (int i = 0; i < displayRefs.length; i++) ...[
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 0 ? PdfColors.white : zebraLight,
                border: pw.Border(
                  bottom: pw.BorderSide(color: outlineBorder, width: 0.5),
                ),
              ),
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: lavenderLight,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      displayRefs[i]['date']?.toString() ?? 'Reflection',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 7.5,
                        color: lavenderDark,
                      ),
                    ),
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: pw.Text(
                    displayRefs[i]['text']?.toString() ?? '',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 8,
                      color: obsidianBlack,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildGoalsTable({
    required List<Map<String, dynamic>> goals,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor obsidianBlack,
    required PdfColor outlineBorder,
    required PdfColor zebraLight,
    required PdfColor electricLime,
    required PdfColor limeLight,
    required PdfColor limeDark,
    required PdfColor lavenderLight,
    required PdfColor lavenderDark,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: outlineBorder, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(6.5),
          1: pw.FlexColumnWidth(3.5),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: obsidianBlack,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            children: [
              _buildTableHeaderCell('Goal Title', boldFont),
              _buildTableHeaderCell('Status', boldFont),
            ],
          ),
          for (int i = 0; i < goals.length; i++) ...[
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 0 ? PdfColors.white : zebraLight,
                border: pw.Border(
                  bottom: pw.BorderSide(color: outlineBorder, width: 0.5),
                ),
              ),
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    goals[i]['title']?.toString() ?? '',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 7.5,
                      color: obsidianBlack,
                    ),
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: pw.BoxDecoration(
                      color: goals[i]['completed'] == true
                          ? electricLime
                          : lavenderLight,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      goals[i]['completed'] == true ? 'Completed' : 'Pending',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 6.5,
                        color: goals[i]['completed'] == true
                            ? obsidianBlack
                            : lavenderDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildActivitiesTable({
    required List<Map<String, dynamic>> activities,
    required pw.Font boldFont,
    required pw.Font baseFont,
    required PdfColor obsidianBlack,
    required PdfColor outlineBorder,
    required PdfColor zebraLight,
    required PdfColor lavenderLight,
    required PdfColor lavenderDark,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: outlineBorder, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(3.0),
          1: pw.FlexColumnWidth(3.0),
          2: pw.FlexColumnWidth(4.0),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: obsidianBlack,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            children: [
              _buildTableHeaderCell('Activity', boldFont),
              _buildTableHeaderCell('Duration', boldFont),
              _buildTableHeaderCell('Metrics', boldFont),
            ],
          ),
          for (int i = 0; i < activities.take(5).length; i++) ...[
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 0 ? PdfColors.white : zebraLight,
                border: pw.Border(
                  bottom: pw.BorderSide(color: outlineBorder, width: 0.5),
                ),
              ),
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    (activities[i]['type']?.toString() ?? 'Activity')
                        .toUpperCase(),
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 7.5,
                      color: obsidianBlack,
                    ),
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    '${activities[i]['durationMinutes'] ?? 0} mins',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 7.5,
                      color: PdfColor.fromHex('#52575F'),
                    ),
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    activities[i]['distanceKm'] != null
                        ? '${activities[i]['distanceKm']} km • ${activities[i]['calories'] ?? 0} kcal'
                        : '${activities[i]['posesCompleted'] ?? 0} poses',
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 7.5,
                      color: PdfColor.fromHex('#52575F'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEmptyStateBox({
    required String message,
    required pw.Font baseFont,
    required PdfColor surfaceWhite,
    required PdfColor outlineBorder,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: surfaceWhite,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: outlineBorder, width: 0.8),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(
          font: baseFont,
          fontSize: 8,
          color: PdfColor.fromHex('#72767E'),
        ),
      ),
    );
  }

  // --- SAVE & DOWNLOAD CAPABILITIES ---

  /// Saves the generated PDF bytes to the device's storage and returns the resulting File.
  Future<File> savePdfToDevice({
    required Uint8List pdfBytes,
    String? customFileName,
  }) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = customFileName ?? 'Habitrak_Progress_Report_$timestamp.pdf';

    // 1. On Android, try the primary public Download directory first
    if (Platform.isAndroid) {
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download');
        if (await publicDownloadDir.exists()) {
          final file = File('${publicDownloadDir.path}/$fileName');
          await file.writeAsBytes(pdfBytes, flush: true);
          debugPrint('PDF successfully written to public Downloads: ${file.path}');
          return file;
        }
      } catch (e) {
        debugPrint('Could not write to /storage/emulated/0/Download: $e');
      }
    }

    // 2. Try getDownloadsDirectory
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes, flush: true);
        return file;
      }
    } catch (e) {
      debugPrint('getDownloadsDirectory failed: $e');
    }

    // 3. Try getExternalStorageDirectory
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null && await extDir.exists()) {
        final file = File('${extDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes, flush: true);
        return file;
      }
    } catch (e) {
      debugPrint('getExternalStorageDirectory failed: $e');
    }

    // 4. Default to ApplicationDocumentsDirectory
    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  /// Opens the native system Print / Save-as-PDF interface
  Future<bool> printOrPreviewPdf({
    required Uint8List pdfBytes,
    String fileName = 'Habitrak_Progress_Report.pdf',
  }) async {
    return Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }

  /// Opens the native system share sheet
  Future<bool> sharePdf({
    required Uint8List pdfBytes,
    String fileName = 'Habitrak_Progress_Report.pdf',
  }) async {
    return Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
      subject: 'My Habitrak Progress Report',
      body: 'Attached is my certified personal progress report generated from Habitrak.',
    );
  }
}
