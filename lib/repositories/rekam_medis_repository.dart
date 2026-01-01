// File: lib/repositories/rekam_medis_repository.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/rekam_medis_model.dart';
import '../services/audit_service.dart';

class RekamMedisRepository extends ChangeNotifier {
  final Box<RekamMedisModel> _rmBox = Hive.box<RekamMedisModel>('rmBox');

  // NOTE: Di main.dart, kita harus tambahkan Hive.openBox('rmBox');

  // --- FUNGSI C (CREATE / Input RM Baru) ---
  Future<String> addRekamMedis({
    required String antrianId,
    required String pasienId,
    required String dokterId,
    required String keluhan,
    required String diagnosa,
    required String tindakan,
    required bool membutuhkanResep,
    String? performedBy,
  }) async {
    final newId = 'RM-${DateTime.now().millisecondsSinceEpoch}';

    final newRM = RekamMedisModel(
      rmId: newId,
      antrianId: antrianId,
      pasienId: pasienId,
      dokterId: dokterId,
      tanggalPeriksa: DateTime.now(),
      keluhan: keluhan,
      diagnosa: diagnosa,
      tindakan: tindakan,
      membutuhkanResep: membutuhkanResep,
    );

    await _rmBox.put(newId, newRM);
    await AuditService.log(
      'CREATE RM',
      'rmId=$newId; antrianId=$antrianId; pasienId=$pasienId',
      userId: performedBy,
    );
    notifyListeners();
    return newId;
  }

  // --- FUNGSI R (READ - Riwayat Pasien) ---
  List<RekamMedisModel> getRiwayatPasien(String pasienId) {
    return _rmBox.values.where((rm) => rm.pasienId == pasienId).toList()
      // Urutkan dari yang terbaru
      ..sort((a, b) => b.tanggalPeriksa.compareTo(a.tanggalPeriksa));
  }

  // Semua rekam medis (urutan terbaru dulu)
  List<RekamMedisModel> get allRekamMedis => _rmBox.values.toList();

  // Hapus semua Rekam Medis yang terkait pasien
  Future<void> deleteByPasienId(String pasienId) async {
    final entries = _rmBox
        .toMap()
        .entries
        .where((e) => (e.value as RekamMedisModel).pasienId == pasienId)
        .toList();
    for (final e in entries) {
      final r = e.value as RekamMedisModel;
      await _rmBox.delete(e.key);
      await AuditService.log('DELETE RM', 'rmId=${r.rmId}; pasienId=$pasienId');
    }
    notifyListeners();
  }

  // Hapus semua Rekam Medis yang terkait dokter (opsional)
  Future<void> deleteByDokterId(String dokterId) async {
    final entries = _rmBox
        .toMap()
        .entries
        .where((e) => (e.value as RekamMedisModel).dokterId == dokterId)
        .toList();
    for (final e in entries) {
      final r = e.value as RekamMedisModel;
      await _rmBox.delete(e.key);
      await AuditService.log('DELETE RM', 'rmId=${r.rmId}; dokterId=$dokterId');
    }
    notifyListeners();
  }

  // Fungsi R untuk mencari RM berdasarkan ID Antrian
  RekamMedisModel? getRMByAntrianId(String antrianId) {
    return _rmBox.values.firstWhere(
      (rm) => rm.antrianId == antrianId,
      orElse: () => throw Exception('RM tidak ditemukan untuk antrian ini'),
    );
  }
}
