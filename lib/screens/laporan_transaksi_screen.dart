import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/antrian_model.dart';
import '../repositories/antrian_repository.dart';
import '../repositories/pasien_repository.dart';
import '../repositories/rekam_medis_repository.dart';
import '../repositories/resep_repository.dart';

const int _JASA_DOKTER = 50000;

class LaporanTransaksiScreen extends StatefulWidget {
  const LaporanTransaksiScreen({super.key});

  @override
  State<LaporanTransaksiScreen> createState() => _LaporanTransaksiScreenState();
}

class _LaporanTransaksiScreenState extends State<LaporanTransaksiScreen> {
  DateTimeRange? _range;

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final initial =
        _range ?? DateTimeRange(start: DateTime.now(), end: DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
    );
    if (picked != null) setState(() => _range = picked);
  }

  List<AntrianModel> _filterPaid(List<AntrianModel> all) {
    final paid = all.where((a) => a.sudahDibayar).toList();
    if (_range == null) return paid;

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

    return paid
        .where(
          (a) =>
              a.waktuMasuk.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              a.waktuMasuk.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  double _computeObatForAntrian(
    AntrianModel a,
    RekamMedisRepository rmRepo,
    ResepRepository resepRepo,
  ) {
    final rm = rmRepo.getRMByAntrianId(a.antrianId);
    if (rm == null) return 0.0;

    final resepList = resepRepo.allResep
        .where((r) => r.rmId == rm.rmId)
        .toList();
    double biayaObat = 0.0;
    for (final r in resepList) {
      for (final d in r.detailObat) {
        biayaObat += d.jumlah * d.hargaSatuan;
      }
    }
    return biayaObat;
  }

  Future<void> _exportCsv(
    List<AntrianModel> antrianList,
    RekamMedisRepository rmRepo,
    ResepRepository resepRepo,
    PasienRepository pasienRepo,
  ) async {
    if (antrianList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor')),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln(
        'tanggal,antrianId,nomorAntrian,pasien,jasa_dokter,biaya_obat,total',
      );

      for (final a in antrianList) {
        String pasienNama;
        try {
          final pasien = pasienRepo.pasienList.firstWhere(
            (p) => p.pasienId == a.pasienId,
          );
          pasienNama = pasien.namaPasien;
        } catch (_) {
          pasienNama = '—';
        }
        final biayaObat = _computeObatForAntrian(a, rmRepo, resepRepo);
        final total = _JASA_DOKTER + biayaObat;
        buffer.writeln(
          '${_formatDate(a.waktuMasuk)},${a.antrianId},${a.nomorAntrian},${pasienNama},${_JASA_DOKTER},${biayaObat.toStringAsFixed(0)},${total.toStringAsFixed(0)}',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/laporan_transaksi_${DateTime.now().millisecondsSinceEpoch}.csv',
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
    final antrianRepo = Provider.of<AntrianRepository>(context);
    final rmRepo = Provider.of<RekamMedisRepository>(context);
    final resepRepo = Provider.of<ResepRepository>(context);
    final pasienRepo = Provider.of<PasienRepository>(context);

    final rangeText = _range == null
        ? 'Semua tanggal'
        : '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)}';

    final list = _filterPaid(antrianRepo.antrianList);

    final totalPendapatan = list.fold<double>(0.0, (acc, a) {
      final biayaObat = _computeObatForAntrian(a, rmRepo, resepRepo);
      return acc + _JASA_DOKTER + biayaObat;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            tooltip: 'Ekspor CSV',
            icon: const Icon(Icons.download),
            onPressed: () async {
              await _exportCsv(list, rmRepo, resepRepo, pasienRepo);
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
                title: const Text('Ringkasan Penerimaan'),
                subtitle: Text(
                  '${list.length} transaksi • Total: Rp ${totalPendapatan.toStringAsFixed(0)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Ringkasan Transaksi'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Transaksi: ${list.length}'),
                              const SizedBox(height: 8),
                              Text(
                                'Pendapatan total: Rp ${totalPendapatan.toStringAsFixed(0)}',
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
              child: list.isEmpty
                  ? const Center(
                      child: Text('Tidak ada transaksi untuk rentang ini.'),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final a = list[i];
                        String pasienNama;
                        try {
                          final pasien = pasienRepo.pasienList.firstWhere(
                            (p) => p.pasienId == a.pasienId,
                          );
                          pasienNama = pasien.namaPasien;
                        } catch (_) {
                          pasienNama = '—';
                        }
                        final biayaObat = _computeObatForAntrian(
                          a,
                          rmRepo,
                          resepRepo,
                        );
                        final total = _JASA_DOKTER + biayaObat;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ExpansionTile(
                            title: Text(
                              '${_formatDate(a.waktuMasuk)} • Antrian ${a.nomorAntrian} • ${pasienNama}',
                            ),
                            subtitle: Text(
                              'Total: Rp ${total.toStringAsFixed(0)}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jasa Dokter: Rp ${_JASA_DOKTER.toStringAsFixed(0)}',
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Biaya Obat: Rp ${biayaObat.toStringAsFixed(0)}',
                                    ),
                                    const SizedBox(height: 8),
                                  ],
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
