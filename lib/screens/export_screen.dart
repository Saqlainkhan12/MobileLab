import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/task_provider.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = ExportService.instance;
  final TextEditingController _emailController = TextEditingController();
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCsvExport() async {
    final tasks = context.read<TaskProvider>().tasks;
    if (tasks.isEmpty) {
      _showEmptyWarning();
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Generating CSV file...';
    });

    try {
      final file = await _exportService.exportTasksToCsv(tasks);
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV file saved: ${file.path.split(Platform.pathSeparator).last}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _exportService.shareFile(file, text: 'Here is my TaskFlow CSV Export.'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to export CSV: $e');
    }
  }

  Future<void> _handlePdfExport({bool previewOnly = false}) async {
    final tasks = context.read<TaskProvider>().tasks;
    if (tasks.isEmpty) {
      _showEmptyWarning();
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Generating PDF report...';
    });

    try {
      final file = await _exportService.exportTasksToPdf(tasks);
      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (previewOnly) {
        await Printing.layoutPdf(
          onLayout: (format) async => file.readAsBytesSync(),
          name: 'TaskFlow_Report',
        );
      } else {
        await _exportService.shareFile(file, subject: 'TaskFlow PDF Report');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to generate PDF: $e');
    }
  }

  Future<void> _handleEmailExport() async {
    final tasks = context.read<TaskProvider>().tasks;
    if (tasks.isEmpty) {
      _showEmptyWarning();
      return;
    }

    final email = _emailController.text.trim();
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Preparing email summary...';
    });

    try {
      await _exportService.sendEmailSummary(tasks, recipientEmail: email.isEmpty ? null : email);
      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to send email: $e');
    }
  }

  void _showEmptyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No tasks available to export. Please add some tasks first!')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final taskProvider = context.watch<TaskProvider>();
    final total = taskProvider.totalCount;
    final completed = taskProvider.completedCount;
    final pending = total - completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & Share Tasks'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Data Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Back up your tasks or share formatted reports across multiple formats.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildExportStat('Total', '$total'),
                        _buildExportStat('Completed', '$completed'),
                        _buildExportStat('Pending', '$pending'),
                        _buildExportStat(
                          'Rate',
                          '${total == 0 ? 0 : ((completed / total) * 100).round()}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // 1. PDF Export Card
              _buildOptionCard(
                context,
                title: 'Export to PDF Report',
                description: 'Generate a clean, formatted document with statistics and task tables.',
                icon: Icons.picture_as_pdf_rounded,
                iconColor: Colors.redAccent,
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => _handlePdfExport(previewOnly: true),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Preview'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _handlePdfExport(previewOnly: false),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share PDF'),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideX(begin: 0.08, end: 0),
              const SizedBox(height: 16),

              // 2. CSV Export Card
              _buildOptionCard(
                context,
                title: 'Export to CSV Spreadsheet',
                description: 'Export all task data to CSV format, compatible with Excel and Google Sheets.',
                icon: Icons.table_chart_rounded,
                iconColor: Colors.green,
                actions: [
                  FilledButton.icon(
                    onPressed: _handleCsvExport,
                    icon: const Icon(Icons.file_download_rounded, size: 18),
                    label: const Text('Export & Share CSV'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideX(begin: 0.08, end: 0),
              const SizedBox(height: 16),

              // 3. Email Export Card
              _buildOptionCard(
                context,
                title: 'Send via Email',
                description: 'Send a structured summary of your tasks directly to your email inbox or colleague.',
                icon: Icons.mark_email_read_rounded,
                iconColor: Colors.blueAccent,
                customBody: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter recipient email (optional)',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                actions: [
                  FilledButton.icon(
                    onPressed: _handleEmailExport,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Email Summary'),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 350.ms).slideX(begin: 0.08, end: 0),
              const SizedBox(height: 32),
            ],
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage ?? 'Processing...',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    Widget? customBody,
    required List<Widget> actions,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (customBody != null) ...[
              const SizedBox(height: 12),
              customBody,
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
