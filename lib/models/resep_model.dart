// File: lib/models/resep_model.dart

import 'package:hive/hive.dart';
part 'resep_model.g.dart';

@HiveType(typeId: 7) // typeId harus unik!
class ResepDetailModel extends HiveObject {
  @HiveField(0)
  String obatId; // FK ke ObatModel

  @HiveField(1)
  String namaObat; // Cache nama obat

  @HiveField(2)
  int jumlah;

  @HiveField(3)
  double hargaSatuan; // Harga saat resep dibuat

  @HiveField(4)
  String aturanPakai;

  ResepDetailModel({
    required this.obatId,
    required this.namaObat,
    required this.jumlah,
    required this.hargaSatuan,
    required this.aturanPakai,
  });
}

@HiveType(typeId: 8) // typeId harus unik!
class ResepModel extends HiveObject {
  @HiveField(0)
  String resepId;

  @HiveField(1)
  String rmId; // FK ke RekamMedisModel

  @HiveField(2)
  String pasienId;

  @HiveField(3)
  DateTime tanggalResep;

  @HiveField(4)
  List<ResepDetailModel> detailObat; // List obat yang diresepkan

  @HiveField(5)
  bool isDisiapkan; // Status: Sudah diambil/diproses Apoteker

  ResepModel({
    required this.resepId,
    required this.rmId,
    required this.pasienId,
    required this.tanggalResep,
    required this.detailObat,
    this.isDisiapkan = false,
  });
}
