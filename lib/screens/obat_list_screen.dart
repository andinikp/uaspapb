// File: lib/screens/obat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/obat_repository.dart';
import '../models/obat_model.dart';
import 'obat_form_screen.dart'; // Akan dibuat setelah ini

class ObatListScreen extends StatelessWidget {
  final bool lowStockOnly;
  final int threshold;

  const ObatListScreen({
    super.key,
    this.lowStockOnly = false,
    this.threshold = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lowStockOnly
              ? 'Inventaris Obat - Stok ≤ $threshold'
              : 'Inventaris Obat',
        ),
        backgroundColor: Colors.purple,
      ),
      body: Consumer<ObatRepository>(
        builder: (context, repo, child) {
          final all = repo.obatList;
          final obatList = lowStockOnly
              ? all.where((o) => o.stokSaatIni <= threshold).toList()
              : all;

          if (obatList.isEmpty) {
            return Center(
              child: Text(
                lowStockOnly
                    ? 'Tidak ada obat dengan stok ≤ $threshold.'
                    : 'Belum ada data obat. Silahkan tambahkan.',
              ),
            );
          }

          return ListView.builder(
            itemCount: obatList.length,
            itemBuilder: (context, index) {
              final obat = obatList[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  leading: const Icon(Icons.medication, color: Colors.purple),
                  title: Text(
                    obat.namaObat,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Stok: ${obat.stokSaatIni} ${obat.satuan} | Harga: Rp ${obat.hargaJual.toStringAsFixed(0)}',
                  ),

                  // Tombol Edit
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ObatFormScreen(
                          obat: obat,
                        ), // Kirim objek untuk Edit
                      ),
                    );
                  },

                  // Tombol Delete
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, repo, obat),
                  ),
                ),
              );
            },
          );
        },
      ),

      // Floating Button (Tombol Tambah)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  const ObatFormScreen(), // Tanpa objek untuk Tambah
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ObatRepository repo,
    ObatModel obat,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Obat'),
        content: Text('Anda yakin ingin menghapus data ${obat.namaObat}?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await repo.deleteObat(obat.obatId); // Panggil fungsi DELETE
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${obat.namaObat} berhasil dihapus!'),
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(ctx).pop();
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
