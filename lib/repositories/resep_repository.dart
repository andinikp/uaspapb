// File: lib/repositories/resep_repository.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/resep_model.dart';
import '../repositories/obat_repository.dart'; // Untuk update stok
import '../services/audit_service.dart';

class ResepRepository extends ChangeNotifier {
  final Box<ResepModel> _resepBox = Hive.box<ResepModel>('resepBox');
  // NOTE: Di main.dart, kita harus tambahkan Hive.openBox('resepBox');

  // Ambil resep yang belum diproses (isDisiapkan = false)
  List<ResepModel> get resepMenunggu =>
      _resepBox.values.where((r) => !r.isDisiapkan).toList();

  // Ambil semua resep
  List<ResepModel> get allResep => _resepBox.values.toList();

  // --- FUNGSI C (CREATE / Buat Resep) oleh DOKTER ---
  Future<void> addResep({
    required String rmId,
    required String pasienId,
    required List<ResepDetailModel> detailObat,
    String? performedBy,
  }) async {
    final newId = 'RES-${DateTime.now().millisecondsSinceEpoch}';

    final newResep = ResepModel(
      resepId: newId,
      rmId: rmId,
      pasienId: pasienId,
      tanggalResep: DateTime.now(),
      detailObat: detailObat,
      isDisiapkan: false,
    );

    await _resepBox.put(newId, newResep);
    await AuditService.log(
      'CREATE Resep',
      'resepId=$newId; rmId=$rmId; pasienId=$pasienId',
      userId: performedBy,
    );
    notifyListeners();
  }

  // --- FUNGSI U (UPDATE / Proses Resep) oleh APOTEKER ---
  Future<void> prosesResep(
    String resepId,
    ObatRepository obatRepo, {
    String? performedBy,
  }) async {
    final resep = _resepBox.get(resepId);
    if (resep != null && !resep.isDisiapkan) {
      // 1. Kurangi stok obat di ObatRepository
      for (var detail in resep.detailObat) {
        // Jika obatId yang tersimpan tidak ada di inventaris, coba cari berdasarkan nama
        final exists = obatRepo.obatList.any((o) => o.obatId == detail.obatId);
        if (exists) {
          await obatRepo.kurangiStok(
            obatId: detail.obatId,
            jumlah: detail.jumlah,
            performedBy: performedBy,
          );
        } else {
          try {
            final matchByName = obatRepo.obatList.firstWhere(
              (o) => o.namaObat.toLowerCase() == detail.namaObat.toLowerCase(),
            );
            await obatRepo.kurangiStok(
              obatId: matchByName.obatId,
              jumlah: detail.jumlah,
              performedBy: performedBy,
            );
          } catch (e) {
            // Tidak ditemukan berdasarkan nama
            throw Exception(
              'Obat "${detail.namaObat}" tidak ditemukan di inventaris.',
            );
          }
        }
      }

      // 2. Tandai resep sebagai sudah diproses
      resep.isDisiapkan = true;
      await resep.save();

      await AuditService.log(
        'PROSES Resep',
        'resepId=$resepId; pasienId=${resep.pasienId}',
        userId: performedBy,
      );

      notifyListeners();
    }
  }

  // Hapus resep berdasarkan pasienId
  Future<void> deleteByPasienId(String pasienId) async {
    final entries = _resepBox
        .toMap()
        .entries
        .where((e) => (e.value as ResepModel).pasienId == pasienId)
        .toList();
    for (final e in entries) {
      final r = e.value as ResepModel;
      await _resepBox.delete(e.key);
      await AuditService.log(
        'DELETE Resep',
        'resepId=${r.resepId}; pasienId=$pasienId',
      );
    }
    notifyListeners();
  }

  // Hapus resep berdasarkan rmId
  Future<void> deleteByRmId(String rmId) async {
    final entries = _resepBox
        .toMap()
        .entries
        .where((e) => (e.value as ResepModel).rmId == rmId)
        .toList();
    for (final e in entries) {
      final r = e.value as ResepModel;
      await _resepBox.delete(e.key);
      await AuditService.log(
        'DELETE Resep',
        'resepId=${r.resepId}; rmId=$rmId',
      );
    }
    notifyListeners();
  }
}
