import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  // ==================== CSV EXPORT ====================

  String _toCsvString(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final val = cell?.toString() ?? '';
        if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
          return '"${val.replaceAll('"', '""')}"';
        }
        return val;
      }).join(',');
    }).join('\r\n');
  }

  Future<File> exportTasksToCsv(List<Task> tasks) async {
    final List<List<dynamic>> rows = [];

    // Header row
    rows.add([
      'Task ID',
      'Title',
      'Description',
      'Category',
      'Priority',
      'Status',
      'Progress %',
      'Due Date',
      'Is Repeated',
      'Repeat Rule',
      'Subtasks Count',
      'Completed Subtasks',
      'Created At',
      'Completed At',
    ]);

    // Data rows
    for (final task in tasks) {
      rows.add([
        task.id ?? '',
        task.title,
        task.description ?? '',
        task.category,
        task.priority.displayName,
        task.isCompleted ? 'Completed' : 'Pending',
        '${task.progressPercentage}%',
        _dateFormat.format(task.dueDate),
        task.isRepeated ? 'Yes' : 'No',
        task.repeatConfig.summaryText,
        task.subtaskCount,
        task.completedSubtaskCount,
        _dateFormat.format(task.createdAt),
        task.completedAt != null ? _dateFormat.format(task.completedAt!) : '',
      ]);
    }

    final csvData = _toCsvString(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/tasks_export_$timestamp.csv');

    await file.writeAsString(csvData);
    return file;
  }

  // ==================== PDF EXPORT ====================

  Future<File> exportTasksToPdf(List<Task> tasks) async {
    final pdf = pw.Document();

    final completedCount = tasks.where((t) => t.isCompleted).length;
    final pendingCount = tasks.length - completedCount;
    final overdueCount = tasks.where((t) => t.isOverdue).length;
    final completionRate = tasks.isEmpty ? 0 : ((completedCount / tasks.length) * 100).round();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TaskFlow Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Task Management Application Summary',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Total: ${tasks.length} Tasks',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.indigo700),
            pw.SizedBox(height: 12),

            // Statistics Summary Boxes
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfStatBox('Total Tasks', '${tasks.length}', PdfColors.blue50),
                _buildPdfStatBox('Completed', '$completedCount', PdfColors.green50),
                _buildPdfStatBox('Pending', '$pendingCount', PdfColors.orange50),
                _buildPdfStatBox('Overdue', '$overdueCount', PdfColors.red50),
                _buildPdfStatBox('Completion', '$completionRate%', PdfColors.indigo50),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tasks Table
            pw.Text(
              'Task Breakdown',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                '#',
                'Title',
                'Category',
                'Priority',
                'Due Date',
                'Progress',
                'Status',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo800,
              ),
              cellHeight: 28,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: List<List<dynamic>>.generate(tasks.length, (index) {
                final t = tasks[index];
                return [
                  (index + 1).toString(),
                  t.title,
                  t.category,
                  t.priority.displayName,
                  DateFormat('yyyy-MM-dd').format(t.dueDate),
                  '${t.progressPercentage}% (${t.completedSubtaskCount}/${t.subtaskCount})',
                  t.isCompleted ? 'Completed' : (t.isOverdue ? 'Overdue' : 'Pending'),
                ];
              }),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generated automatically by TaskFlow App',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/tasks_report_$timestamp.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildPdfStatBox(String label, String value, PdfColor bgColor) {
    return pw.Container(
      width: 95,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // ==================== EMAIL EXPORT ====================

  String generateEmailBody(List<Task> tasks) {
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final pendingCount = tasks.length - completedCount;
    final overdueCount = tasks.where((t) => t.isOverdue).length;

    final buffer = StringBuffer();
    buffer.writeln('TaskFlow - Task Management Summary');
    buffer.writeln('====================================');
    buffer.writeln('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
    buffer.writeln('Total Tasks: ${tasks.length}');
    buffer.writeln('Completed: $completedCount | Pending: $pendingCount | Overdue: $overdueCount\n');

    buffer.writeln('--- TASK LIST ---');
    for (int i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      final status = t.isCompleted ? '[DONE]' : (t.isOverdue ? '[OVERDUE]' : '[PENDING]');
      buffer.writeln('${i + 1}. $status ${t.title}');
      buffer.writeln('   Category: ${t.category} | Priority: ${t.priority.displayName}');
      buffer.writeln('   Due: ${_dateFormat.format(t.dueDate)}');
      if (t.isRepeated) {
        buffer.writeln('   Repeat: ${t.repeatConfig.summaryText}');
      }
      if (t.subtasks.isNotEmpty) {
        buffer.writeln('   Subtasks: ${t.completedSubtaskCount}/${t.subtasks.length} completed (${t.progressPercentage}%)');
        for (final st in t.subtasks) {
          buffer.writeln('     - [${st.isCompleted ? "x" : " "}] ${st.title}');
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('Sent from TaskFlow App');
    return buffer.toString();
  }

  Future<void> sendEmailSummary(List<Task> tasks, {String? recipientEmail}) async {
    final body = generateEmailBody(tasks);
    final subject = 'TaskFlow Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: recipientEmail ?? '',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: body,
            subject: subject,
          ),
        );
      }
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: body,
          subject: subject,
        ),
      );
    }
  }

  // ==================== SHARE FILE HELPER ====================

  Future<void> shareFile(File file, {String? subject, String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject ?? 'TaskFlow Export File',
        text: text,
      ),
    );
  }
}
