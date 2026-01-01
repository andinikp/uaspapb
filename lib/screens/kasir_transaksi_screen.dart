// File: lib/screens/kasir_transaksi_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/antrian_model.dart';
import '../models/resep_model.dart';
import '../repositories/antrian_repository.dart';
import '../repositories/pasien_repository.dart';
import '../repositories/resep_repository.dart';
import '../repositories/rekam_medis_repository.dart';

// Biaya tetap
const int JASA_DOKTER = 50000;

class KasirTransaksiScreen extends StatelessWidget {
  const KasirTransaksiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Pasien'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer4<AntrianRepository, PasienRepository, ResepRepository, RekamMedisRepository>(
        builder: (context, antrianRepo, pasienRepo, resepRepo, rmRepo, child) {
          // Filter antrian: Status Selesai DAN Belum Dibayar
          final listSiapBayar = antrianRepo.antrianList
              .where(
                (a) => a.status == AntrianStatus.selesai && !a.sudahDibayar,
              )
              .toList();

          if (listSiapBayar.isEmpty) {
            return const Center(
              child: Text('Tidak ada antrian yang siap dibayar.'),
            );
          }

          String formatRupiah(double v) {
            final intVal = v.round();
            final s = intVal.toString();
            // tambahkan pemisah ribuan sederhana
            final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
            return s.replaceAllMapped(reg, (m) => '.');
          }

          return ListView.builder(
            itemCount: listSiapBayar.length,
            itemBuilder: (context, index) {
              final antrian = listSiapBayar[index];
              final pasien = pasienRepo.pasienList.firstWhere(
                (p) => p.pasienId == antrian.pasienId,
              );

              // Coba cari RM yang berhubungan dengan antrian ini
              String? rmIdForAntrian;
              try {
                final rm = rmRepo.getRMByAntrianId(antrian.antrianId);
                // gunakan null-aware akses agar tidak error jika rm null
                rmIdForAntrian = rm?.rmId;
              } catch (_) {
                rmIdForAntrian = null; // tidak ditemukan
              }

              // Cek apakah ada Resep terkait (berdasarkan rmId yang kita temukan)
              final resepTerkait = rmIdForAntrian == null
                  ? <ResepModel>[]
                  : resepRepo.allResep
                        .where((r) => r.rmId == rmIdForAntrian)
                        .toList();

              // Hitung Biaya Obat
              double biayaObat = 0.0;
              for (var resep in resepTerkait) {
                for (var detail in resep.detailObat) {
                  biayaObat += detail.hargaSatuan * detail.jumlah;
                }
              }

              final totalBiaya = JASA_DOKTER + biayaObat;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Antrian ${antrian.nomorAntrian}: ${pasien.namaPasien}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            'TOTAL: Rp ${formatRupiah(totalBiaya)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jasa Dokter: Rp ${formatRupiah(JASA_DOKTER.toDouble())}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Biaya Obat: Rp ${formatRupiah(biayaObat)}',
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      if (resepTerkait.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Tidak ada resep terkait atau RM belum dibuat untuk antrian ini.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _showPaymentDialog(
                            context,
                            antrian,
                            totalBiaya,
                            antrianRepo,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text(
                            'Bayar & Selesaikan',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
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

  // Fungsi dummy untuk mendapatkan RM ID berdasarkan Antrian ID (Karena kita tidak bisa mencari RM di Hive tanpa key)
  // Ini memerlukan logic sederhana, di aplikasi nyata, Antrian model akan punya FK ke RM ID.
  // Untuk saat ini, kita anggap RM ID sama dengan Antrian ID agar kode berjalan (walaupun tidak 100% tepat)
  String _getRmIdByAntrian(String antrianId) {
    // Di Langkah 11, kita membuat RM ID = 'RM-' + timestamp.
    // Di sini kita tidak punya akses ke Repository RM untuk mencari.
    // ASUMSI: kita cari resep berdasarkan rmId yang sama dengan antrianId (Sesuai contoh di L15).
    return antrianId; // Ini adalah ASUMSI yang harus diperbaiki jika kita membuat FK yang benar.
  }

  // Dialog Pembayaran
  void _showPaymentDialog(
    BuildContext context,
    AntrianModel antrian,
    double totalBiaya,
    AntrianRepository antrianRepo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Total yang harus dibayar untuk Antrian ${antrian.nomorAntrian} adalah:\nRp ${totalBiaya.toStringAsFixed(0)}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Tandai antrian sebagai sudah dibayar
              antrian.sudahDibayar = true;
              antrian.save(); // Panggil save dari HiveObject
              antrianRepo
                  .notifyListeners(); // Manual notifikasi karena save() tidak memanggil notif

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran Sukses! Transaksi Selesai.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Bayar & Selesaikan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
