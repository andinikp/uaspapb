// File: lib/repositories/obat_repository.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/obat_model.dart';
import '../services/audit_service.dart';

class ObatRepository extends ChangeNotifier {
  final Box<ObatModel> _obatBox = Hive.box<ObatModel>('obatBox');
  // NOTE: Di main.dart, kita harus tambahkan Hive.openBox('obatBox');

  List<ObatModel> get obatList => _obatBox.values.toList();

  // --- FUNGSI C (CREATE / Tambah Obat Baru) ---
  Future<void> addObat({
    required String namaObat,
    required String satuan,
    required int stokSaatIni,
    required double hargaJual,
    String? performedBy,
  }) async {
    final newId = 'OBT-${DateTime.now().millisecondsSinceEpoch}';

    final newObat = ObatModel(
      obatId: newId,
      namaObat: namaObat,
      satuan: satuan,
      stokSaatIni: stokSaatIni,
      hargaJual: hargaJual,
    );

    await _obatBox.put(newId, newObat);
    await AuditService.log(
      'CREATE Obat',
      'obatId=$newId; nama=$namaObat',
      userId: performedBy,
    );
    notifyListeners();
  }

  // --- FUNGSI U (UPDATE / Edit Obat/Stok) ---
  Future<void> updateObat(ObatModel obat, {String? performedBy}) async {
    // Jika objek ada di Box (HiveObject ter-manage), update field dan panggil save().
    // Jika tidak, gunakan put agar tidak memanggil save() pada objek yang bukan bagian dari box.
    final existing = _obatBox.get(obat.obatId);
    if (existing != null) {
      existing.namaObat = obat.namaObat;
      existing.satuan = obat.satuan;
      existing.stokSaatIni = obat.stokSaatIni;
      existing.hargaJual = obat.hargaJual;
      await existing.save();
    } else {
      await _obatBox.put(obat.obatId, obat);
    }

    await AuditService.log(
      'UPDATE Obat',
      'obatId=${obat.obatId}; nama=${obat.namaObat}',
      userId: performedBy,
    );
    notifyListeners();
  }

  // --- FUNGSI U SPESIAL: Pengurangan Stok (untuk Alur Farmasi) ---
  Future<void> kurangiStok({
    required String obatId,
    required int jumlah,
    String? performedBy,
  }) async {
    final obat = _obatBox.get(obatId);
    if (obat != null) {
      if (obat.stokSaatIni >= jumlah) {
        obat.stokSaatIni -= jumlah;
        await obat.save();
        await AuditService.log(
          'KURANGI_STOK',
          'obatId=$obatId; jumlah=$jumlah',
          userId: performedBy,
        );
        notifyListeners();
      } else {
        throw Exception('Stok obat ${obat.namaObat} tidak mencukupi.');
      }
    }
  }

  // --- FUNGSI D (DELETE / Hapus Obat) ---
  Future<void> deleteObat(String obatId, {String? performedBy}) async {
    final deleted = _obatBox.get(obatId);
    await _obatBox.delete(obatId);
    await AuditService.log(
      'DELETE Obat',
      'obatId=$obatId; nama=${deleted?.namaObat ?? ''}',
      userId: performedBy,
    );
    notifyListeners();
  }
}
