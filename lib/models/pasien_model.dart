// File: lib/models/pasien_model.dart

import 'package:hive/hive.dart';
part 'pasien_model.g.dart'; // File akan di-generate otomatis

@HiveType(
  typeId: 2,
) // typeId harus unik, jangan bentrok dengan UserModel (typeId: 1)
class PasienModel extends HiveObject {
  @HiveField(0)
  String pasienId; // ID unik (key di Hive)

  @HiveField(1)
  String namaPasien;

  @HiveField(2)
  String nik;

  @HiveField(3)
  DateTime tglLahir;

  @HiveField(4)
  String alamat;

  @HiveField(5)
  String noTelp;

  @HiveField(6)
  String? jenisKelamin; // baru: 'Laki-laki' | 'Perempuan' | null

  PasienModel({
    required this.pasienId,
    required this.namaPasien,
    required this.nik,
    required this.tglLahir,
    required this.alamat,
    required this.noTelp,
    this.jenisKelamin,
  });
}
