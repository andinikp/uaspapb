// File: lib/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pasien_list_screen.dart';
import 'tambah_antrian_screen.dart';
import 'laporan_audit_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF0F766E); // deep teal
    final gold = const Color(0xFFB58900);

    Widget styledCard({
      required IconData icon,
      required String title,
      String? subtitle,
      VoidCallback? onTap,
      Color? iconBg,
    }) {
      return Card(
        elevation: 6,
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
              const Icon(Icons.local_hospital, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manajemen Klinik — Rekam Medis',
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
          icon: Icons.person_add,
          title: '1. Manajemen Pasien (CRUD)', // Struktur tetap sama
          subtitle: 'Tambah, lihat, edit, hapus data pasien.',
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (c) => const PasienListScreen()));
          },
          iconBg: accent,
        ),

        styledCard(
          icon: Icons.queue_play_next,
          title: '2. Tambah Antrian Baru',
          subtitle: 'Daftarkan pasien ke antrian dokter.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (c) => const TambahAntrianScreen()),
            );
          },
          iconBg: Colors.green,
        ),

        // Aktifkan menu yang sebelumnya statis
        styledCard(
          icon: Icons.manage_accounts,
          title: '3. Manajemen Pengguna (CRUD)',
          subtitle: 'Mengatur akun Dokter, Kasir, dan Apoteker.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => const PenggunaManagementScreen(),
              ),
            );
          },
          iconBg: Colors.indigo,
        ),

        styledCard(
          icon: Icons.bar_chart,
          title: '4. Laporan & Audit',
          subtitle: 'Lihat ringkasan aktivitas & laporan harian.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (c) => const LaporanAuditScreen()),
            );
          },
          iconBg: Colors.purple,
        ),

        // Lokasi Klinik (membuka Google Maps dengan query Ceria Medika)
        styledCard(
          icon: Icons.map_outlined,
          title: '5. Lokasi Klinik Ceria Medika',
          subtitle: 'Buka lokasi di Google Maps',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final uri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=Ceria+Medika+Klinik',
            );
            try {
              final opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!opened) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Gagal membuka Maps')),
                );
              }
            } catch (e) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Tidak dapat membuka Maps')),
              );
            }
          },
          iconBg: Colors.teal,
        ),

        // Tambahkan menu Admin lainnya...
      ],
    );
  }
}

// Minimal placeholder screen untuk Manajemen Pengguna (aktif dan mobile-friendly)
class PenggunaManagementScreen extends StatefulWidget {
  const PenggunaManagementScreen({super.key});

  @override
  State<PenggunaManagementScreen> createState() =>
      _PenggunaManagementScreenState();
}

class _PenggunaManagementScreenState extends State<PenggunaManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final users = auth.allUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Pengguna')),
      body: users.isEmpty
          ? const Center(child: Text('Belum ada pengguna.'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(u.namaLengkap.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(u.namaLengkap),
                    subtitle: Text('${u.email} • ${u.role.name}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await _showEditDialog(context, auth, u);
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Hapus Pengguna'),
                              content: Text('Hapus pengguna ${u.namaLengkap}?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await auth.deleteUser(u.userId);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, auth),
        label: const Text('Tambah'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, AuthService auth) async {
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole role = UserRole.admin;

    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Pengguna'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Masukkan nama' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Masukkan email' : null,
              ),
              DropdownButtonFormField<UserRole>(
                value: role,
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => role = v ?? role,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final id = 'U${DateTime.now().millisecondsSinceEpoch}';
              final user = UserModel(
                userId: id,
                namaLengkap: namaCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                role: role,
              );
              await auth.addUser(user);
              Navigator.of(context).pop(true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() {});
  }

  Future<void> _showEditDialog(
    BuildContext context,
    AuthService auth,
    UserModel user,
  ) async {
    final namaCtrl = TextEditingController(text: user.namaLengkap);
    final emailCtrl = TextEditingController(text: user.email);
    UserRole role = user.role;
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Pengguna'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Masukkan nama' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Masukkan email' : null,
              ),
              DropdownButtonFormField<UserRole>(
                value: role,
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => role = v ?? role,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              user.namaLengkap = namaCtrl.text.trim();
              user.email = emailCtrl.text.trim();
              user.role = role;
              await auth.updateUser(user);
              Navigator.of(context).pop(true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() {});
  }
}

// File: lib/screens/dokter_dashboard.dart (Hanya contoh)
// ... Buat file ini dengan tampilan menu Dokter ...
class DokterDashboard extends StatelessWidget {
  const DokterDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Dashboard Dokter: Menu Antrian & Rekam Medis'),
    );
  }
}

// ... Lakukan hal yang sama untuk Kasir dan Apoteker ...
