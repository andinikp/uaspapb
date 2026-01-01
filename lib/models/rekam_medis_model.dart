// File: lib/models/rekam_medis_model.dart

import 'package:hive/hive.dart';
part 'rekam_medis_model.g.dart'; // File akan di-generate otomatis

@HiveType(typeId: 5) // typeId harus unik!
class RekamMedisModel extends HiveObject {
  @HiveField(0)
  String rmId;

  @HiveField(1)
  String antrianId; // FK ke AntrianModel (untuk track kunjungan)

  @HiveField(2)
  String pasienId; // FK ke PasienModel

  @HiveField(3)
  String dokterId; // FK ke UserModel (Dokter)

  @HiveField(4)
  DateTime tanggalPeriksa;

  @HiveField(5)
  String keluhan;

  @HiveField(6)
  String diagnosa;

  @HiveField(7)
  String tindakan;

  @HiveField(8)
  bool membutuhkanResep; // Flag untuk lanjut ke Farmasi

  RekamMedisModel({
    required this.rmId,
    required this.antrianId,
    required this.pasienId,
    required this.dokterId,
    required this.tanggalPeriksa,
    required this.keluhan,
    required this.diagnosa,
    required this.tindakan,
    required this.membutuhkanResep,
  });
}
