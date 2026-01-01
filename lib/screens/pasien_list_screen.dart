// File: lib/screens/pasien_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/pasien_repository.dart';
import '../repositories/antrian_repository.dart';
import '../repositories/rekam_medis_repository.dart';
import '../repositories/resep_repository.dart';
import '../models/pasien_model.dart';
import 'pasien_form_screen.dart';
import 'pasien_riwayat_screen.dart';

class PasienListScreen extends StatelessWidget {
  const PasienListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Ambil PasienRepository
    final pasienRepo = Provider.of<PasienRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pasien'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Consumer<PasienRepository>(
        builder: (context, repo, child) {
          final pasienList = repo.pasienList;

          if (pasienList.isEmpty) {
            return const Center(child: Text('Belum ada data pasien.'));
          }

          // 2. Tampilkan Daftar Pasien
          return ListView.builder(
            itemCount: pasienList.length,
            itemBuilder: (context, index) {
              final pasien = pasienList[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueGrey),
                  title: Text(
                    pasien.namaPasien,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'ID: ${pasien.pasienId} | Telp: ${pasien.noTelp}',
                  ),

                  // 3. Tombol Edit (Navigasi ke Form)
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PasienFormScreen(
                          pasien: pasien,
                        ), // Kirim objek untuk Edit
                      ),
                    );
                  },

                  // 4. Tombol Delete
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _confirmDelete(context, pasienRepo, pasien),
                  ),
                ),
              );
            },
          );
        },
      ),

      // 5. Floating Button (Tombol Tambah)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  const PasienFormScreen(), // Tanpa objek untuk Tambah
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PasienRepository repo,
    PasienModel pasien,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus data ${pasien.namaPasien}?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final antrianRepo = Provider.of<AntrianRepository>(
                context,
                listen: false,
              );
              final rmRepo = Provider.of<RekamMedisRepository>(
                context,
                listen: false,
              );
              final resepRepo = Provider.of<ResepRepository>(
                context,
                listen: false,
              );
              await repo.deletePasienAndCascade(
                pasien.pasienId,
                antrianRepo: antrianRepo,
                rmRepo: rmRepo,
                resepRepo: resepRepo,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${pasien.namaPasien} berhasil dihapus!'),
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
