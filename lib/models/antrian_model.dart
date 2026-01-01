// File: lib/models/antrian_model.dart

import 'package:hive/hive.dart';
part 'antrian_model.g.dart'; // File akan di-generate otomatis

@HiveType(typeId: 3) // typeId harus unik!
enum AntrianStatus {
  @HiveField(0)
  menunggu, // Default: Menunggu dipanggil Dokter
  @HiveField(1)
  diperiksa, // Sedang diperiksa Dokter
  @HiveField(2)
  selesai, // Sudah selesai diperiksa (siap ke Kasir)
  @HiveField(3)
  menungguObat, // Menunggu apoteker untuk menyiapkan resep
}

@HiveType(typeId: 4) // typeId harus unik!
class AntrianModel extends HiveObject {
  @HiveField(0)
  String antrianId;

  @HiveField(1)
  String pasienId; // FK ke PasienModel

  @HiveField(2)
  String dokterId; // FK ke UserModel (Dokter)

  @HiveField(3)
  int nomorAntrian;

  @HiveField(4)
  AntrianStatus status;

  @HiveField(5)
  DateTime waktuMasuk;

  @HiveField(6)
  bool sudahDibayar = false;

  AntrianModel({
    required this.antrianId,
    required this.pasienId,
    required this.dokterId,
    required this.nomorAntrian,
    this.status = AntrianStatus.menunggu,
    required this.waktuMasuk,
    this.sudahDibayar = false,
  });
}
