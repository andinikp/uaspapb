// File: lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Import Dashboard Spesifik (Kita akan buat di Langkah 6)
import 'admin_dashboard.dart' hide DokterDashboard;
import 'dokter_dashboard.dart';
import 'kasir_dashboard.dart';
import 'apoteker_dashboard.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // Update setiap 30 detik agar jam relatif "live" tanpa membebani
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Consumer: Dengarkan perubahan di AuthService
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Ambil role pengguna saat ini
        final currentRole = authService.currentRole;
        final userName = authService.currentUser?.namaLengkap ?? 'Pengguna';

        Widget bodyWidget;

        // 2. Logika Pemilihan Dashboard berdasarkan Role
        switch (currentRole) {
          case UserRole.admin:
            bodyWidget = const AdminDashboard();
            break;
          case UserRole.dokter:
            bodyWidget = const DokterDashboard();
            break;
          case UserRole.kasir:
            bodyWidget = const KasirDashboard();
            break;
          case UserRole.apoteker:
            bodyWidget = const ApotekerDashboard();
            break;
          case null:
            // Jika role null (Belum login/Logout), kembali ke Login Screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            });
            bodyWidget = const Center(child: CircularProgressIndicator());
            break;
        }

        // 3. Tampilan Utama
        final dateStr = _formatDate(_now);
        final timeStr = _formatTime(_now);
        // Warna teks AppBar — ambil dari theme bila tersedia, fallback ke hitam gelap
        final appBarForeground =
            Theme.of(context).appBarTheme.titleTextStyle?.color ??
            Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.onPrimary ??
            Colors.black87;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            backgroundColor: Theme.of(context).primaryColorDark,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang, $userName (${currentRole.toString().split('.').last.toUpperCase()})',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • $timeStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              // Tampilkan waktu juga di sisi kanan agar lebih terlihat pada layar sempit
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  authService.logout(); // Panggil fungsi logout
                  // AuthService akan memicu notifikasi dan currentRole akan jadi null,
                  // lalu HomeScreen akan otomatis redirect ke Login Screen.
                },
              ),
            ],
          ),
          body: bodyWidget,
        );
      },
    );
  }
}
