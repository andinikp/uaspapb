import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/audit_model.dart';
import '../repositories/audit_repository.dart';
import '../services/auth_service.dart';
import '../widgets/ringkasan_aktivitas_widget.dart';

class ReportItem {
  final DateTime date;
  final String title;
  final String summary;
  final List<List<String>> rows; // for CSV export

  ReportItem({
    required this.date,
    required this.title,
    required this.summary,
    this.rows = const [],
  });
}

class LaporanAuditScreen extends StatefulWidget {
  const LaporanAuditScreen({super.key});

  @override
  State<LaporanAuditScreen> createState() => _LaporanAuditScreenState();
}

class _LaporanAuditScreenState extends State<LaporanAuditScreen> {
  DateTimeRange? _range;
  List<ReportItem> _allReports = [];

  // Summary state for a single work day
  DateTime _summaryDay = DateTime.now();
  Map<String, int> _summaryCounts = {};
  int _summaryTotal = 0;

  @override
  void initState() {
    super.initState();
    // Try to load from AuditRepository; fallback to sample data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final repo = Provider.of<AuditRepository>(context, listen: false);
        final entries = repo.getAll();
        if (entries.isNotEmpty) {
          setState(() {
            _allReports = entries
                .map(
                  (e) => ReportItem(
                    date: e.timestamp,
                    title: e.action,
                    summary: e.details,
                    rows: [],
                  ),
                )
                .toList();
          });
          // load today's summary after repo is available
          _loadDailySummary(_summaryDay);
          return;
        }
      } catch (_) {
        // ignore if provider or box not ready
      }

      // Fallback sample data
      final now = DateTime.now();
      setState(() {
        _allReports = List.generate(20, (i) {
          final date = now.subtract(Duration(days: i * 2));
          return ReportItem(
            date: date,
            title: 'Laporan ${i + 1}',
            summary: 'Ringkasan singkat untuk laporan ${i + 1}',
            rows: [
              ['Kolom A', 'Kolom B', 'Kolom C'],
              ['Data 1', 'Data 2', 'Data 3'],
            ],
          );
        });
      });
      // still attempt to load today's summary even when using sample data
      _loadDailySummary(_summaryDay);
    });
  }

  List<ReportItem> get _filteredReports {
    if (_range == null) return _allReports;
    final start = DateTime(
      _range!.start.year,
      _range!.start.month,
      _range!.start.day,
    );
    final end = DateTime(
      _range!.end.year,
      _range!.end.month,
      _range!.end.day,
      23,
      59,
      59,
    );
    return _allReports
        .where(
          (r) =>
              r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              r.date.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final initial =
        _range ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _pickSummaryDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _summaryDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) await _loadDailySummary(picked);
  }

  Future<void> _loadDailySummary(DateTime day) async {
    try {
      final repo = Provider.of<AuditRepository>(context, listen: false);
      final entries = repo.getByRange(day, day);
      final counts = <String, int>{};
      for (final e in entries) {
        counts[e.action] = (counts[e.action] ?? 0) + 1;
      }
      setState(() {
        _summaryDay = day;
        _summaryCounts = counts;
        _summaryTotal = entries.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat ringkasan: $e')));
    }
  }

  // Parse semi-colon separated key=value pairs into a map
  Map<String, String> _parseDetails(String raw) {
    final map = <String, String>{};
    final s = raw.trim();
    if (s.isEmpty) return map;
    try {
      final parts = s.split(';');
      for (var p in parts) {
        p = p.trim();
        if (p.isEmpty) continue;
        final idx = p.indexOf('=');
        if (idx > 0) {
          final k = p.substring(0, idx).trim();
          final v = p.substring(idx + 1).trim();
          map[k] = v;
        } else {
          map[p] = '';
        }
      }
    } catch (_) {
      // ignore parse errors
    }
    return map;
  }

  void _showActivityDiagram(
    String title,
    Map<String, String> details,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diagram Aktivitas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stepBox('User', Icons.person),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward),
                      ),
                      _stepBox(
                        title,
                        Icons.playlist_add_check,
                        subtitle: date.toIso8601String().split('T').first,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward),
                      ),
                      _stepBox('Repository', Icons.storage),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward),
                      ),
                      _stepBox('Audit Log', Icons.receipt_long),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (details.isNotEmpty) ...[
                const Text('Rincian yang tercatat:'),
                const SizedBox(height: 8),
                ...details.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Text(
                          '${e.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _stepBox(String label, IconData icon, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    final reports = _filteredReports;
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada laporan untuk diekspor')),
      );
      return;
    }
    try {
      final buffer = StringBuffer();
      buffer.writeln('Date,Title,Summary');
      for (final r in reports) {
        final date = _formatDate(r.date);
        final title = r.title.replaceAll(',', ' ');
        final summary = r.summary.replaceAll(',', ' ');
        buffer.writeln('$date,$title,$summary');
        for (final row in r.rows) {
          buffer.writeln(
            row.map((c) => '"${c.replaceAll('"', '""')}"').join(','),
          );
        }
        buffer.writeln();
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan CSV disimpan di: ${file.path}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengekspor CSV: $e')));
    }
  }

  Future<void> _exportPdf() async {
    final reports = _filteredReports;
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada laporan untuk diekspor')),
      );
      return;
    }

    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Audit',
                style: pw.TextStyle(fontSize: 18),
              ),
            ),
            pw.Text(
              'Rentang: ${_range == null ? 'Semua tanggal' : '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)}'}',
            ),
            pw.SizedBox(height: 10),
            ...reports.map((r) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        _formatDate(r.date),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(r.title),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(r.summary),
                  pw.SizedBox(height: 6),
                  if (r.rows.isNotEmpty)
                    pw.Table.fromTextArray(
                      data: <List<String>>[for (final row in r.rows) row],
                    ),
                  pw.Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'laporan_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengekspor PDF: $e')));
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Ekspor CSV'),
            onTap: () {
              Navigator.of(context).pop();
              _exportCsv();
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Ekspor PDF'),
            onTap: () {
              Navigator.of(context).pop();
              _exportPdf();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = _range == null
        ? 'Semua tanggal'
        : '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)}';
    final reports = _filteredReports;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan & Audit')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.date_range),
                        title: const Text('Rentang Tanggal'),
                        subtitle: Text(rangeText),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: _pickRange,
                              child: const Text('Pilih'),
                            ),
                            if (_range != null)
                              IconButton(
                                tooltip: 'Bersihkan',
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _range = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ringkasan aktivitas klinik (grid + recent)
                    const RingkasanAktivitasWidget(),

                    const SizedBox(height: 12),

                    // Ringkasan Harian
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.timeline),
                        title: Text('Ringkasan: ${_formatDate(_summaryDay)}'),
                        subtitle: Text('$_summaryTotal entri'),
                        trailing: IconButton(
                          tooltip: 'Pilih tanggal ringkasan',
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickSummaryDay,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_summaryTotal == 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Tidak ada aktivitas pada tanggal ini.'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _summaryCounts.entries
                            .map((e) => Chip(label: Text('${e.key} • ${e.value}')))
                            .toList(),
                      ),

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            final repo = Provider.of<AuditRepository>(
                              context,
                              listen: false,
                            );
                            final auth = Provider.of<AuthService>(
                              context,
                              listen: false,
                            );
                            final entry = AuditModel(
                              timestamp: DateTime.now(),
                              action: 'Contoh Log',
                              userId: auth.currentUser?.userId,
                              details:
                                  'Ini adalah log contoh yang dibuat untuk pengujian.',
                            );
                            await repo.addLog(entry);
                            // reload
                            final entries = repo.getAll();
                            setState(() {
                              _allReports = entries
                                  .map(
                                    (e) => ReportItem(
                                      date: e.timestamp,
                                      title: e.action,
                                      summary: e.details,
                                    ),
                                  )
                                  .toList();
                            });
                            // refresh daily summary (for selected summary day)
                            await _loadDailySummary(_summaryDay);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Log contoh ditambahkan')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menambahkan log contoh: $e'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah log contoh'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Menampilkan ${reports.length} laporan',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showExportOptions,
                          icon: const Icon(Icons.download),
                          label: const Text('Ekspor'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // reports list (shrink-wrapped so outer scroll handles scrolling)
                    reports.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 36.0),
                              child: Text('Tidak ada laporan untuk rentang tanggal ini.'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reports.length,
                            itemBuilder: (context, i) {
                              final r = reports[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.insert_drive_file_outlined,
                                  ),
                                  title: Text(r.title),
                                  subtitle: Text(
                                    '${_formatDate(r.date)} • ${r.summary}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) {
                                          final raw = r.summary ?? '';
                                          final parsed = _parseDetails(raw);

                                          return AlertDialog(
                                            title: Text(r.title),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Tanggal: ${_formatDate(r.date)}',
                                                  ),
                                                  const SizedBox(height: 8),

                                                  if (parsed.isNotEmpty) ...[
                                                    const Text('Rincian:'),
                                                    const SizedBox(height: 8),
                                                    ...parsed.entries.map((e) => Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                              vertical: 4.0),
                                                          child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                              Expanded(child: Text(e.value)),
                                                            ],
                                                          ),
                                                        )),
                                                  ] else if (raw
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                    Text(raw),
                                                  ],

                                                  if (r.rows.isNotEmpty) ...[
                                                    const SizedBox(height: 12),
                                                    const Text('Data:'),
                                                    const SizedBox(height: 6),
                                                    ...r.rows.map(
                                                      (row) => Text(row.join(' | ')),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  Clipboard.setData(
                                                    ClipboardData(text: raw),
                                                  );
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Rincian disalin ke clipboard',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.copy),
                                                label: const Text('Salin'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  _showActivityDiagram(
                                                    r.title,
                                                    parsed,
                                                    r.date,
                                                  );
                                                },
                                                child: const Text(
                                                  'Diagram Aktivitas',
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Tutup'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                    // end reports
                  ],
                ),
              ),
            ),
        );
      },
    ),
  );
}
}