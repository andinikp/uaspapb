// File: lib/screens/apoteker_dashboard.dart (BARU/Diperbarui)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/obat_repository.dart';
import '../repositories/resep_repository.dart';
import 'obat_list_screen.dart'; // Import screen baru
import 'resep_menunggu_screen.dart';
import 'laporan_penjualan_screen.dart';

class ApotekerDashboard extends StatelessWidget {
  const ApotekerDashboard({super.key});

  static const Color primary = Color(0xFF00695C); // Rekam-medis teal
  static const Color accent = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.local_pharmacy, size: 32, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Apoteker • Ceria Medika',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Kelola stok obat, proses resep, dan pantau inventaris klinik.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                0.95, // beri sedikit ruang vertikal agar tidak overflow
            children: [
              _buildCard(
                context,
                icon: Icons.inventory_2,
                title: 'Manajemen Stok',
                subtitle: 'Tambah / Edit / Hapus Obat',
                color: primary,
                onTap: () async {
                  try {
                    // Prefetch to ensure repo available
                    final _ = Provider.of<ObatRepository>(
                      context,
                      listen: false,
                    ).obatList;
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (c) => const ObatListScreen()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal membuka Manajemen Stok: $e'),
                      ),
                    );
                  }
                },
              ),

              _buildCard(
                context,
                icon: Icons.receipt_long,
                title: 'Resep Masuk',
                subtitle: 'Proses resep dari Dokter',
                color: accent,
                onTap: () async {
                  try {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (c) => const ResepMenungguScreen(),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membuka Resep Masuk: $e')),
                    );
                  }
                },
              ),

              Builder(
                builder: (ctx) {
                  // Hitung jumlah obat dengan stok ≤ threshold (default 5)
                  final lowThreshold = 5;
                  final lowCount = Provider.of<ObatRepository>(
                    ctx,
                  ).obatList.where((o) => o.stokSaatIni <= lowThreshold).length;

                  return _buildCard(
                    context,
                    icon: Icons.report_problem,
                    title: 'Stok Rendah',
                    subtitle: 'Obat dengan stok ≤ $lowThreshold ($lowCount)',
                    color: Colors.orange.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (c) => const ObatListScreen(
                            lowStockOnly: true,
                            threshold: 5,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              Builder(
                builder: (ctx) {
                  final soldCount = Provider.of<ResepRepository>(
                    ctx,
                  ).allResep.where((r) => r.isDisiapkan).length;

                  return _buildCard(
                    context,
                    icon: Icons.analytics,
                    title: 'Laporan Penjualan',
                    subtitle: 'Ringkasan & penjualan obat ($soldCount terjual)',
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (c) => const LaporanPenjualanScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Helper actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 28, 187, 62),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Obat'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (c) => const ObatListScreen()),
                  );
                },
              ),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withOpacity(0.18)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Cari Obat'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (c) => const ObatListScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Small tips
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.black54),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: Gunakan fitur "Stok Rendah" untuk cepat menemukan obat yang perlu restock.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Selengkapnya',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
