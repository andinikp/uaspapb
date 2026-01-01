import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/pasien_repository.dart';
import '../repositories/resep_repository.dart';
import '../repositories/obat_repository.dart';
import '../repositories/audit_repository.dart';
import '../screens/laporan_audit_screen.dart';

class RingkasanAktivitasWidget extends StatelessWidget {
  final int recentLimit;
  final int lowStockThreshold;

  const RingkasanAktivitasWidget({
    super.key,
    this.recentLimit = 5,
    this.lowStockThreshold = 5,
  });

  String _formatCurrency(double v) {
    // simple formatting without intl
    final s = v.toStringAsFixed(0);
    final chars = s.split('').reversed.toList();
    final parts = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      parts.add(
        chars.sublist(i, i + 3 > chars.length ? chars.length : i + 3).join(),
      );
    }
    return 'Rp ' + parts.join('.').split('').reversed.join();
  }

  IconData _iconForAction(String action) {
    if (action.toLowerCase().contains('create'))
      return Icons.add_circle_outline;
    if (action.toLowerCase().contains('update')) return Icons.edit;
    if (action.toLowerCase().contains('delete')) return Icons.delete_outline;
    if (action.toLowerCase().contains('proses')) return Icons.inventory_2;
    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    final pasienCount = Provider.of<PasienRepository>(
      context,
    ).pasienList.length;
    final obatRepo = Provider.of<ObatRepository>(context);
    final resepRepo = Provider.of<ResepRepository>(context);
    final auditRepo = Provider.of<AuditRepository>(context);

    final stokKritis = obatRepo.obatList
        .where((o) => o.stokSaatIni <= lowStockThreshold)
        .length;

    final processed = resepRepo.allResep.where((r) => r.isDisiapkan).toList();
    final pendapatan = processed.fold<double>(
      0.0,
      (acc, r) =>
          acc +
          r.detailObat.fold(0.0, (ac, d) => ac + d.jumlah * d.hargaSatuan),
    );

    final recent = auditRepo.getAll().toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final recentSlice = recent.take(recentLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid stats: two on top, one centered below (keeps three cards but different layout)
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    title: 'Total Pasien',
                    value: '$pasienCount',
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    title: 'Pendapatan',
                    value: _formatCurrency(pendapatan),
                    icon: Icons.monetization_on,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.48,
                child: _statCard(
                  context,
                  title: 'Stok Obat Kritis',
                  value: '$stokKritis',
                  icon: Icons.report_problem,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Recent activity header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (c) => const LaporanAuditScreen()),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Recent list (shrink-wrapped column to avoid nested scrolls)
        if (recentSlice.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Belum ada aktivitas.'),
          ),
        ] else ...[
          Column(
            children: recentSlice.map((a) {
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withOpacity(0.12),
                      child: Icon(
                        _iconForAction(a.action),
                        color: Colors.blueAccent,
                      ),
                    ),
                    title: Text(a.action),
                    subtitle: Text(
                      '${a.userId != null ? a.userId! + ' • ' : ''}${a.timestamp.toLocal().toString().split('.').first}',
                    ),
                  ),
                  const Divider(height: 8),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      color: Colors.blueAccent.withOpacity(0.08),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
