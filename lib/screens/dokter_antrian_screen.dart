// File: lib/screens/dokter_antrian_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/antrian_model.dart';
import '../repositories/antrian_repository.dart';
import '../repositories/pasien_repository.dart';
import '../services/auth_service.dart';
import 'input_rm_screen.dart';

class DokterAntrianScreen extends StatelessWidget {
  const DokterAntrianScreen({super.key});

  static const Color primary = Color(0xFF00695C);
  static const Color accent = Color(0xFF00ACC1);

  // Fungsi untuk mendapatkan warna berdasarkan status
  Color _getStatusColor(AntrianStatus status) {
    switch (status) {
      case AntrianStatus.menunggu:
        return Colors.amber;
      case AntrianStatus.diperiksa:
        return Colors.blue;
      case AntrianStatus.selesai:
        return Colors.green;
      case AntrianStatus.menungguObat:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ambil ID Dokter yang sedang login
    final currentUserId = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser?.userId;

    // 2. Jika ID Dokter tidak ada, tampilkan error
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Antrian Dokter')),
        body: const Center(child: Text('Error: User ID tidak ditemukan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Antrian Anda'),
        backgroundColor: primary,
      ),
      body: Consumer2<AntrianRepository, PasienRepository>(
        // Consumer2 memungkinkan kita mendengarkan 2 Repository sekaligus
        builder: (context, antrianRepo, pasienRepo, child) {
          // Filter antrian yang ditujukan HANYA untuk Dokter ini DAN statusnya BUKAN selesai
          final myAntrianList =
              antrianRepo.antrianAktif
                  .where((a) => a.dokterId == currentUserId)
                  .toList()
                ..sort(
                  (a, b) => a.nomorAntrian.compareTo(b.nomorAntrian),
                ); // Urutkan berdasarkan nomor antrian

          if (myAntrianList.isEmpty) {
            return const Center(
              child: Text('Tidak ada antrian aktif saat ini.'),
            );
          }

          return ListView.builder(
            itemCount: myAntrianList.length,
            itemBuilder: (context, index) {
              final antrian = myAntrianList[index];
              try {
                // Safe lookup pasien (tidak melempar)
                final matches = pasienRepo.pasienList.where(
                  (p) => p.pasienId == antrian.pasienId,
                );
                final pasienNama = matches.isNotEmpty
                    ? matches.first.namaPasien
                    : 'Pasien tidak ditemukan';
                final pasienIdStr = antrian.pasienId;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      try {
                        if (antrian.status != AntrianStatus.selesai) {
                          await antrianRepo.updateAntrianStatus(
                            antrian.antrianId,
                            AntrianStatus.diperiksa,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  InputRMScreen(antrian: antrian),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Info'),
                              content: const Text('Antrian sudah selesai.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membuka antrian: $e')),
                        );
                      }
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(antrian.status),
                        child: Text(
                          antrian.nomorAntrian.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        pasienNama,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Status: ${antrian.status.name.toUpperCase()}',
                      ),
                      trailing: _buildActionButton(
                        context,
                        antrianRepo,
                        antrian,
                      ),
                      onTap: () async {
                        try {
                          if (antrian.status != AntrianStatus.selesai) {
                            await antrianRepo.updateAntrianStatus(
                              antrian.antrianId,
                              AntrianStatus.diperiksa,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    InputRMScreen(antrian: antrian),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Info'),
                                content: const Text('Antrian sudah selesai.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal membuka antrian: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              } catch (e, st) {
                debugPrint('Error building antrian tile: $e\n$st');
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                    title: const Text('Data antrian bermasalah'),
                    subtitle: Text(e.toString()),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  // Widget untuk menampilkan Tombol Aksi (Panggil / Selesaikan)
  Widget _buildActionButton(
    BuildContext context,
    AntrianRepository repo,
    AntrianModel antrian,
  ) {
    if (antrian.status == AntrianStatus.menunggu) {
      // Tombol Panggil -> Langsung navigasi ke form RM
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 140),
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Pastikan update status selesai sebelum navigasi
              await repo.updateAntrianStatus(
                antrian.antrianId,
                AntrianStatus.diperiksa,
              );
              // lalu navigasi
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InputRMScreen(antrian: antrian),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal panggil antrian: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            minimumSize: const Size(72, 36),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Panggil & Isi RM',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (antrian.status == AntrianStatus.diperiksa) {
      return const SizedBox(
        width: 120,
        child: Text(
          'Sedang Diperiksa...',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: Color(0xFF00695C)),
        ),
      );
    }

    if (antrian.status == AntrianStatus.menungguObat) {
      return const SizedBox(
        width: 120,
        child: Text(
          'Menunggu Obat...',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: Colors.deepPurple),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
