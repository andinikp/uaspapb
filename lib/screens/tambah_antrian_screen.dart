// File: lib/screens/tambah_antrian_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/pasien_model.dart';
import '../repositories/pasien_repository.dart';
import '../repositories/antrian_repository.dart';
import '../services/auth_service.dart'; // Untuk mendapatkan list Dokter

class TambahAntrianScreen extends StatefulWidget {
  const TambahAntrianScreen({super.key});

  @override
  State<TambahAntrianScreen> createState() => _TambahAntrianScreenState();
}

class _TambahAntrianScreenState extends State<TambahAntrianScreen> {
  PasienModel? _selectedPasien;
  UserModel? _selectedDokter;

  // Kita buat daftar dokter dan pasien tersedia di initState
  List<UserModel> _listDokter = [];
  List<PasienModel> _listPasien = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi daftar dokter dan pasien saat screen dimuat
    final authService = Provider.of<AuthService>(context, listen: false);
    final pasienRepo = Provider.of<PasienRepository>(context, listen: false);

    // Filter semua user yang role-nya DOKTER
    _listDokter = authService.userBox.values
        .where((user) => user.role == UserRole.dokter)
        .toList();

    // Ambil semua daftar pasien
    _listPasien = pasienRepo.pasienList;
  }

  void _submitAntrian() async {
    if (_selectedPasien == null || _selectedDokter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih Pasien dan Dokter terlebih dahulu!'),
        ),
      );
      return;
    }

    final antrianRepo = Provider.of<AntrianRepository>(context, listen: false);

    // Panggil fungsi CREATE Antrian
    await antrianRepo.addAntrian(
      pasienId: _selectedPasien!.pasienId,
      dokterId: _selectedDokter!.userId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Antrian baru untuk ${_selectedPasien!.namaPasien} berhasil dibuat!',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Antrian Baru'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- 1. Dropdown PILIH PASIEN ---
            const Text(
              'Pilih Pasien:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            DropdownButtonFormField<PasienModel>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: _selectedPasien,
              hint: const Text('Cari/Pilih Pasien yang Sudah Terdaftar'),
              items: _listPasien.map((pasien) {
                return DropdownMenuItem(
                  value: pasien,
                  child: Text('${pasien.namaPasien} (${pasien.pasienId})'),
                );
              }).toList(),
              onChanged: (PasienModel? newValue) {
                setState(() {
                  _selectedPasien = newValue;
                });
              },
              validator: (value) => value == null ? 'Wajib pilih pasien' : null,
            ),

            const SizedBox(height: 20),

            // --- 2. Dropdown PILIH DOKTER ---
            const Text(
              'Pilih Dokter Tujuan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            DropdownButtonFormField<UserModel>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: _selectedDokter,
              hint: const Text('Pilih Dokter yang Bertugas'),
              items: _listDokter.map((dokter) {
                return DropdownMenuItem(
                  value: dokter,
                  child: Text(dokter.namaLengkap),
                );
              }).toList(),
              onChanged: (UserModel? newValue) {
                setState(() {
                  _selectedDokter = newValue;
                });
              },
              validator: (value) => value == null ? 'Wajib pilih dokter' : null,
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _submitAntrian,
              icon: const Icon(Icons.send),
              label: const Text(
                'Daftarkan ke Antrian',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
