// File: lib/screens/pasien_riwayat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/resep_model.dart';
import '../repositories/rekam_medis_repository.dart';
import '../repositories/resep_repository.dart';
import '../models/rekam_medis_model.dart';

class PasienRiwayatScreen extends StatelessWidget {
  final String pasienId;
  final String namaPasien;

  const PasienRiwayatScreen({
    super.key,
    required this.pasienId,
    required this.namaPasien,
  });

  // Widget untuk menampilkan detail Resep
  Widget _buildResepDetail(ResepModel resep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final detail in resep.detailObat)
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 4),
            child: Text(
              '• ${detail.namaObat} (${detail.jumlah} ${detail.aturanPakai}) - Rp ${detail.hargaSatuan.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Kunjungan: $namaPasien'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Consumer2<RekamMedisRepository, ResepRepository>(
        builder: (context, rmRepo, resepRepo, child) {
          // 1. Ambil semua Riwayat RM pasien ini
          final riwayatRM = rmRepo.getRiwayatPasien(pasienId);

          if (riwayatRM.isEmpty) {
            return const Center(
              child: Text('Pasien ini belum memiliki riwayat Rekam Medis.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: riwayatRM.length,
            itemBuilder: (context, index) {
              final rm = riwayatRM[index];

              // 2. Cari Resep yang terkait dengan RM ini
              final resepTerkait = resepRepo.allResep
                  .where((r) => r.rmId == rm.rmId)
                  .toList();

              // Format tanggal
              final tanggal =
                  '${rm.tanggalPeriksa.day}/${rm.tanggalPeriksa.month}/${rm.tanggalPeriksa.year}';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kunjungan pada: $tanggal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.indigo,
                        ),
                      ),
                      Text(
                        'Dokter: ${rm.dokterId}',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(),

                      // Keluhan & Diagnosa
                      _buildDetailRow('Keluhan', rm.keluhan),
                      _buildDetailRow('Diagnosa', rm.diagnosa),
                      _buildDetailRow(
                        'Tindakan',
                        rm.tindakan.isEmpty ? '-' : rm.tindakan,
                      ),

                      const SizedBox(height: 10),

                      // Detail Resep
                      if (rm.membutuhkanResep && resepTerkait.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resep Obat:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            for (final r in resepTerkait) _buildResepDetail(r),
                          ],
                        )
                      else if (rm.membutuhkanResep && resepTerkait.isEmpty)
                        const Text(
                          'Resep Obat: (Data resep tidak ditemukan, RM menunjukan butuh resep)',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget pembantu untuk Detail RM
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
