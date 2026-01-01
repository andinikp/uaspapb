// File: lib/repositories/antrian_repository.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/antrian_model.dart';
import '../services/audit_service.dart';

class AntrianRepository extends ChangeNotifier {
  final Box<AntrianModel> _antrianBox = Hive.box<AntrianModel>('antrianBox');

  // NOTE: Di main.dart, kita harus tambahkan Hive.openBox('antrianBox');

  // Semua antrian (dipakai oleh Kasir)
  List<AntrianModel> get antrianList => _antrianBox.values.toList();

  // Ambil Antrian yang statusnya BUKAN selesai (untuk Dokter & Admin)
  List<AntrianModel> get antrianAktif {
    return _antrianBox.values
        .where((a) => a.status != AntrianStatus.selesai)
        .toList();
  }

  // --- FUNGSI C (CREATE / Tambah Antrian) oleh ADMIN ---
  Future<void> addAntrian({
    required String pasienId,
    required String dokterId,
    String? performedBy,
  }) async {
    // 1. Tentukan nomor antrian berikutnya
    final today = DateTime.now().day;
    final lastAntrian = _antrianBox.values
        .where((a) => a.waktuMasuk.day == today)
        .toList()
        .length;
    final nextNumber = lastAntrian + 1;

    // 2. Buat objek baru
    final newId = 'A-${DateTime.now().millisecondsSinceEpoch}';
    final newAntrian = AntrianModel(
      antrianId: newId,
      pasienId: pasienId,
      dokterId: dokterId,
      nomorAntrian: nextNumber,
      waktuMasuk: DateTime.now(),
      status: AntrianStatus.menunggu,
    );

    // 3. Simpan dan notifikasi
    await _antrianBox.put(newId, newAntrian);
    await AuditService.log(
      'CREATE Antrian',
      'antrianId=${newId}; pasienId=${pasienId}; dokterId=${dokterId}',
      userId: performedBy,
    );
    notifyListeners();
  }

  // --- FUNGSI U (UPDATE / Update Status) oleh DOKTER ---
  Future<void> updateAntrianStatus(
    String antrianId,
    AntrianStatus newStatus, {
    String? performedBy,
  }) async {
    final antrian = _antrianBox.get(antrianId);
    if (antrian != null) {
      antrian.status = newStatus;
      await antrian.save(); // Simpan perubahan status ke Hive
      await AuditService.log(
        'UPDATE Antrian',
        'antrianId=${antrianId}; status=${newStatus}',
        userId: performedBy,
      );
      notifyListeners();
    }
  }

  // --- FUNGSI R (READ) ---
  AntrianModel? getAntrianById(String id) {
    return _antrianBox.get(id);
  }

  // Hapus semua antrian yang terkait dengan pasienId (cascade)
  Future<void> deleteByPasienId(String pasienId) async {
    final entries = _antrianBox
        .toMap()
        .entries
        .where((e) => (e.value as AntrianModel).pasienId == pasienId)
        .toList();
    for (final e in entries) {
      final a = e.value as AntrianModel;
      await _antrianBox.delete(e.key);
      await AuditService.log(
        'DELETE Antrian',
        'antrianId=${a.antrianId}; pasienId=$pasienId',
      );
    }
    notifyListeners();
  }

  // Hapus semua antrian yang terkait dengan dokterId (cascade)
  Future<void> deleteByDokterId(String dokterId) async {
    final entries = _antrianBox
        .toMap()
        .entries
        .where((e) => (e.value as AntrianModel).dokterId == dokterId)
        .toList();
    for (final e in entries) {
      final a = e.value as AntrianModel;
      await _antrianBox.delete(e.key);
      await AuditService.log(
        'DELETE Antrian',
        'antrianId=${a.antrianId}; dokterId=$dokterId',
      );
    }
    notifyListeners();
  }
}
