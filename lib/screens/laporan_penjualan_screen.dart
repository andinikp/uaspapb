import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../repositories/resep_repository.dart';
import '../repositories/pasien_repository.dart';
import '../models/resep_model.dart';

class LaporanPenjualanScreen extends StatefulWidget {
  const LaporanPenjualanScreen({super.key});

  @override
  State<LaporanPenjualanScreen> createState() => _LaporanPenjualanScreenState();
}

class _LaporanPenjualanScreenState extends State<LaporanPenjualanScreen> {
  DateTimeRange? _range;

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

  List<ResepModel> _filterResep(List<ResepModel> all) {
    final filtered = all.where((r) => r.isDisiapkan).toList();
    if (_range == null) return filtered;
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
    return filtered
        .where(
          (r) =>
              r.tanggalResep.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              r.tanggalResep.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  double _totalForResep(ResepModel r) {
    return r.detailObat.fold(0.0, (acc, d) => acc + d.jumlah * d.hargaSatuan);
  }

  Future<void> _exportCsv(List<ResepModel> resepList) async {
    if (resepList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln('resepId,pasien,nama_obat,jumlah,harga_satuan,subtotal');

      final pasienRepo = Provider.of<PasienRepository>(context, listen: false);

      for (final r in resepList) {
        String pasienNama;
        try {
          final pasien = pasienRepo.pasienList.firstWhere(
            (p) => p.pasienId == r.pasienId,
          );
          pasienNama = pasien.namaPasien;
        } catch (_) {
          pasienNama = 'Tidak diketahui';
        }

        for (final d in r.detailObat) {
          final subtotal = d.jumlah * d.hargaSatuan;
          buffer.writeln(
            '${r.resepId},${pasienNama},${d.namaObat},${d.jumlah},${d.hargaSatuan.toStringAsFixed(0)},${subtotal.toStringAsFixed(0)}',
          );
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/penjualan_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV disimpan di: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengekspor CSV: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<ResepRepository>(context);
    final pasienRepo = Provider.of<PasienRepository>(context);
    final rangeText = _range == null
        ? 'Semua tanggal'
        : '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)}';

    final resepList = _filterResep(repo.allResep);

    final totalRevenue = resepList.fold(
      0.0,
      (acc, r) => acc + _totalForResep(r),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan Obat'),
        actions: [
          IconButton(
            tooltip: 'Ekspor CSV',
            icon: const Icon(Icons.download),
            onPressed: () async {
              await _exportCsv(resepList);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Rentang Tanggal'),
                subtitle: Text(rangeText),
                trailing: TextButton(
                  onPressed: _pickRange,
                  child: const Text('Pilih'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('Total Penjualan'),
                subtitle: Text(
                  '${resepList.length} resep • Pendapatan: Rp ${totalRevenue.toStringAsFixed(0)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    // optional: show breakdown
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Ringkasan Penjualan'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Resep: ${resepList.length}'),
                              const SizedBox(height: 8),
                              Text(
                                'Pendapatan total: Rp ${totalRevenue.toStringAsFixed(0)}',
                              ),
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
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: resepList.isEmpty
                  ? const Center(
                      child: Text('Tidak ada penjualan untuk rentang ini.'),
                    )
                  : ListView.builder(
                      itemCount: resepList.length,
                      itemBuilder: (context, i) {
                        final r = resepList[i];
                        String pasienNama;
                        try {
                          final pasien = pasienRepo.pasienList.firstWhere(
                            (p) => p.pasienId == r.pasienId,
                          );
                          pasienNama = pasien.namaPasien;
                        } catch (e) {
                          pasienNama = '— Tidak diketahui —';
                        }

                        final total = _totalForResep(r);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ExpansionTile(
                            title: Text('${r.resepId} • $pasienNama'),
                            subtitle: Text(
                              '${_formatDate(r.tanggalResep)} • Total: Rp ${total.toStringAsFixed(0)}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  children: r.detailObat.map((d) {
                                    final subtotal = d.jumlah * d.hargaSatuan;
                                    return ListTile(
                                      dense: true,
                                      title: Text(d.namaObat),
                                      subtitle: Text(
                                        '${d.jumlah} x Rp ${d.hargaSatuan.toStringAsFixed(0)}',
                                      ),
                                      trailing: Text(
                                        'Rp ${subtotal.toStringAsFixed(0)}',
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
