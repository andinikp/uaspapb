// File: lib/models/obat_model.dart

import 'package:hive/hive.dart';
part 'obat_model.g.dart'; // File akan di-generate otomatis

@HiveType(typeId: 6) // typeId harus unik!
class ObatModel extends HiveObject {
  @HiveField(0)
  String obatId;

  @HiveField(1)
  String namaObat;

  @HiveField(2)
  String satuan; // Tablet, Botol, Salep, dll.

  @HiveField(3)
  int stokSaatIni;

  @HiveField(4)
  double hargaJual; // Harga per satuan

  ObatModel({
    required this.obatId,
    required this.namaObat,
    required this.satuan,
    required this.stokSaatIni,
    required this.hargaJual,
  });
}
