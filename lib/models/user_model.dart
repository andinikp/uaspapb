// File: lib/models/user_model.dart

import 'package:hive/hive.dart';
part 'user_model.g.dart'; // File akan di-generate otomatis

@HiveType(typeId: 0) // typeId harus unik
enum UserRole {
  @HiveField(0)
  admin,
  @HiveField(1)
  dokter,
  @HiveField(2)
  kasir,
  @HiveField(3)
  apoteker,
}

@HiveType(typeId: 1) // typeId harus unik
class UserModel extends HiveObject {
  // Kita extend HiveObject
  @HiveField(0)
  String userId;

  @HiveField(1)
  String namaLengkap;

  @HiveField(2)
  String email;

  @HiveField(3)
  UserRole role;

  UserModel({
    required this.userId,
    required this.namaLengkap,
    required this.email,
    required this.role,
  });
}
