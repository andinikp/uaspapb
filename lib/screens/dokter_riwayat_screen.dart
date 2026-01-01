import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/rekam_medis_repository.dart';
import '../models/rekam_medis_model.dart';

class DokterRiwayatScreen extends StatelessWidget {
  const DokterRiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<RekamMedisRepository>(context);
    final riwayat = repo.allRekamMedis;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Rekam Medis')),
      body: riwayat.isEmpty
          ? const Center(child: Text('Belum ada rekam medis.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: riwayat.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final RekamMedisModel rm = riwayat[i];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      'RM: ${rm.rmId} • ${rm.tanggalPeriksa.toLocal().toString().split('.').first}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Pasien: ${rm.pasienId} • Dokter: ${rm.dokterId}'),
                        const SizedBox(height: 6),
                        Text('Diagnosa: ${rm.diagnosa}'),
                        Text('Tindakan: ${rm.tindakan}'),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      // Optional: navigate to detail screen in future
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Detail RM belum tersedia'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
