// File: lib/screens/resep_menunggu_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/resep_repository.dart';
import '../repositories/pasien_repository.dart';
import '../repositories/obat_repository.dart';
import '../repositories/rekam_medis_repository.dart';
import '../repositories/antrian_repository.dart';
import '../models/antrian_model.dart';
import '../models/resep_model.dart';

class ResepMenungguScreen extends StatelessWidget {
  const ResepMenungguScreen({super.key});

  // Fungsi untuk memproses resep
  Future<void> _prosesResep(
    BuildContext context,
    ResepModel resep,
    ResepRepository resepRepo,
    ObatRepository obatRepo,
  ) async {
    try {
      // Panggil fungsi prosesResep
      await resepRepo.prosesResep(resep.resepId, obatRepo);

      // Setelah resep diproses oleh apoteker, update status antrian agar masuk ke kasir
      final rmRepo = Provider.of<RekamMedisRepository>(context, listen: false);
      final antrianRepo = Provider.of<AntrianRepository>(
        context,
        listen: false,
      );
      try {
        final rm = rmRepo.allRekamMedis.firstWhere((r) => r.rmId == resep.rmId);
        await antrianRepo.updateAntrianStatus(
          rm.antrianId,
          AntrianStatus.selesai,
        );
      } catch (e) {
        // Jika RM tidak ditemukan, kita cuma log dan lanjutkan
        debugPrint('RM for resep ${resep.resepId} not found: $e');
      }

      // Notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resep ${resep.resepId} berhasil diproses dan stok obat dikurangi.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Notifikasi error (misal: stok tidak cukup)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses resep: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget untuk menampilkan detail obat
  Widget _buildResepDetail(ResepDetailModel detail) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, top: 4.0),
      child: Text(
        '${detail.namaObat} (${detail.jumlah} ${detail.aturanPakai}) - Harga: Rp ${detail.hargaSatuan.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelayanan Resep Masuk'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Consumer3<ResepRepository, PasienRepository, ObatRepository>(
        builder: (context, resepRepo, pasienRepo, obatRepo, child) {
          final listResep = resepRepo.resepMenunggu;

          if (listResep.isEmpty) {
            return const Center(
              child: Text('Tidak ada resep baru yang menunggu diproses.'),
            );
          }

          return ListView.builder(
            itemCount: listResep.length,
            itemBuilder: (context, index) {
              final resep = listResep[index];
              // Lookup pasien dengan aman — jangan lempar exception ke UI
              final matches = pasienRepo.pasienList.where(
                (p) => p.pasienId == resep.pasienId,
              );
              final pasienNama = matches.isNotEmpty
                  ? matches.first.namaPasien
                  : 'Pasien tidak ditemukan';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt, color: Colors.deepPurple),
                  title: Text('Resep untuk: $pasienNama'),
                  subtitle: Text('ID Resep: ${resep.resepId}'),

                  children: [
                    // Detail Obat
                    if (resep.detailObat.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          'Tidak ada obat yang diresepkan — ini notifikasi bahwa pasien langsung ke kasir.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),

                    for (final d in resep.detailObat) _buildResepDetail(d),

                    if (pasienNama == 'Pasien tidak ditemukan')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Perhatian: data pasien tidak ditemukan. Periksa entri pasien atau hapus resep ini jika perlu.',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const Divider(),

                    // Tombol Proses
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _prosesResep(
                            context,
                            resep,
                            resepRepo,
                            obatRepo,
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: resep.detailObat.isEmpty
                            ? const Text(
                                'Tandai & Selesai (kasir sudah menangani)',
                              )
                            : const Text('Siapkan & Proses Resep Ini'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
