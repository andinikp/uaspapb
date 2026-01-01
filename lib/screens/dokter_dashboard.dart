// File: lib/screens/dokter_dashboard.dart (Diperbarui)

import 'package:flutter/material.dart';
import 'dokter_antrian_screen.dart'; // BARU
import 'dokter_riwayat_screen.dart'; // BARU

class DokterDashboard extends StatelessWidget {
  const DokterDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF0F766E);
    final gold = const Color(0xFFB58900);

    Widget styledCard({
      required IconData icon,
      required String title,
      String? subtitle,
      VoidCallback? onTap,
      Color? iconBg,
    }) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconBg ?? accent,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle, style: const TextStyle(color: Colors.black54)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.9), accent.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.medical_services, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Dokter Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Antrian & Rekam Medis',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(),
            ],
          ),
        ),

        styledCard(
          icon: Icons.list_alt,
          title: '1. Daftar Antrian Pasien',
          subtitle: 'Lihat, panggil, dan update status antrian Anda.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (c) => const DokterAntrianScreen()),
            );
          },
          iconBg: accent,
        ),

        styledCard(
          icon: Icons.folder_open,
          title: '2. Riwayat Rekam Medis',
          subtitle: 'Akses data pasien historis.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (c) => const DokterRiwayatScreen()),
            );
          },
          iconBg: Colors.blueGrey,
        ),
      ],
    );
  }
}
