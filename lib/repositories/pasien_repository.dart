// File: lib/repositories/pasien_repository.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pasien_model.dart';
import 'antrian_repository.dart';
import 'rekam_medis_repository.dart';
import 'resep_repository.dart';
import '../models/antrian_model.dart';
import '../models/audit_model.dart';
import '../services/audit_service.dart';

class PasienRepository extends ChangeNotifier {
  // Ambil Box pasien yang sudah diinisialisasi di main.dart
  final Box<PasienModel> _pasienBox = Hive.box<PasienModel>('pasienBox');

  // Ambil semua pasien (digunakan untuk menampilkan List)
  List<PasienModel> get pasienList => _pasienBox.values.toList();

  // --- FUNGSI C (CREATE / Tambah Pasien) ---
  Future<void> addPasien({
    required String namaPasien,
    required String nik,
    required DateTime tglLahir,
    required String alamat,
    required String noTelp,
    String? jenisKelamin,
    String? performedBy,
  }) async {
    final pasien = PasienModel(
      pasienId: 'P${DateTime.now().millisecondsSinceEpoch}',
      namaPasien: namaPasien,
      nik: nik,
      tglLahir: tglLahir,
      alamat: alamat,
      noTelp: noTelp,
      jenisKelamin: jenisKelamin,
    );
    await _pasienBox.add(pasien);
    // Audit
    await AuditService.log(
      'CREATE Pasien',
      'pasienId=${pasien.pasienId}; nama=${pasien.namaPasien}',
      userId: performedBy,
    );
    notifyListeners();
  }

  // --- FUNGSI U (UPDATE / Edit Pasien) ---
  Future<void> updatePasien(PasienModel pasien, {String? performedBy}) async {
    // HiveObject punya key, sehingga kita bisa panggil save() pada objek yang sudah ada
    await pasien.save();

    // Audit
    await AuditService.log(
      'UPDATE Pasien',
      'pasienId=${pasien.pasienId}; nama=${pasien.namaPasien}',
      userId: performedBy,
    );

    notifyListeners();
  }

  // --- FUNGSI D (DELETE / Hapus Pasien) ---
  // Hapus pasien dan cascade: antrian, rekam medis, resep
  Future<void> deletePasienAndCascade(
    String pasienId, {
    AntrianRepository? antrianRepo,
    RekamMedisRepository? rmRepo,
    ResepRepository? resepRepo,
  }) async {
    // Hapus children dulu
    if (resepRepo != null) await resepRepo.deleteByPasienId(pasienId);
    if (rmRepo != null) await rmRepo.deleteByPasienId(pasienId);
    if (antrianRepo != null) await antrianRepo.deleteByPasienId(pasienId);

    // Hapus pasien sendiri
    dynamic targetKey;
    for (final entry in _pasienBox.toMap().entries) {
      final PasienModel p = entry.value as PasienModel;
      if (p.pasienId == pasienId) {
        targetKey = entry.key;
        break;
      }
    }
    if (targetKey != null) {
      final deleted = _pasienBox.get(targetKey) as PasienModel?;
      await _pasienBox.delete(targetKey);
      // Audit
      await AuditService.log(
        'DELETE Pasien',
        'pasienId=$pasienId; nama=${deleted?.namaPasien ?? ''}',
      );
      notifyListeners();
    }
  }

  Future<void> deletePasien(String pasienId) async {
    await deletePasienAndCascade(pasienId);
  }
}
