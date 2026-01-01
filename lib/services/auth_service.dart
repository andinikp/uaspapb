// ...existing code...
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../services/audit_service.dart';
import '../repositories/antrian_repository.dart';

class AuthService extends ChangeNotifier {
  late final Box<UserModel> _userBox;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  UserRole? get currentRole => _currentUser?.role;
  bool get isAuthenticated => _currentUser != null;
  // Expose box agar layar lain (mis. TambahAntrianScreen) bisa mengakses list user
  Box<UserModel> get userBox => _userBox;

  AuthService() {
    // Pastikan box sudah dibuka di main() sebelum AuthService dibuat
    _userBox = Hive.box<UserModel>('userBox');
    _initializeDefaultUsers();
  }

  // --- 1. INISIALISASI DATA DUMMY AWAL ---
  void _initializeDefaultUsers() {
    if (_userBox.isEmpty) {
      _userBox.add(
        UserModel(
          userId: 'A001',
          namaLengkap: 'Admin Sistem',
          email: 'admin@gmail.com',
          role: UserRole.admin,
        ),
      );
      _userBox.add(
        UserModel(
          userId: 'D001',
          namaLengkap: 'Dokter Umum',
          email: 'dokter@gmail.com',
          role: UserRole.dokter,
        ),
      );
      _userBox.add(
        UserModel(
          userId: 'K001',
          namaLengkap: 'Kasir Keuangan',
          email: 'kasir@gmail.com',
          role: UserRole.kasir,
        ),
      );
      _userBox.add(
        UserModel(
          userId: 'P001',
          namaLengkap: 'Apoteker Farmasi',
          email: 'apoteker@gmail.com',
          role: UserRole.apoteker,
        ),
      );
    }
  }

  // --- 2. LOGIKA LOGIN ---
  Future<String?> login(String email, String password) async {
    final simplePassword = email.split('@').first;

    UserModel? user;
    for (final u in _userBox.values.cast<UserModel>()) {
      if (u.email == email) {
        user = u;
        break;
      }
    }

    if (user == null) return 'User tidak ditemukan';

    if (simplePassword == password) {
      _currentUser = user;
      notifyListeners();
      return null;
    } else {
      return 'Password salah';
    }
  }

  // LOGOUT
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // --- CRUD OPERATIONS FOR USERS ---
  List<UserModel> get allUsers => _userBox.values.toList();

  Future<void> addUser(UserModel user, {String? performedBy}) async {
    await _userBox.put(user.userId, user);
    await AuditService.log(
      'CREATE User',
      'userId=${user.userId}; nama=${user.namaLengkap}',
      userId: performedBy,
    );
    notifyListeners();
  }

  Future<void> updateUser(UserModel user, {String? performedBy}) async {
    // if user is HiveObject attached, saving will persist
    try {
      await user.save();
    } catch (_) {
      await _userBox.put(user.userId, user);
    }
    await AuditService.log(
      'UPDATE User',
      'userId=${user.userId}; nama=${user.namaLengkap}',
      userId: performedBy,
    );
    notifyListeners();
  }

  Future<void> deleteUser(String userId, {String? performedBy}) async {
    await _userBox.delete(userId);
    await AuditService.log(
      'DELETE User',
      'userId=$userId',
      userId: performedBy,
    );
    notifyListeners();
  }

  // Hapus user (dokter) dan antrian terkait
  Future<void> deleteUserAndCascade(
    String userId, {
    AntrianRepository? antrianRepo,
  }) async {
    dynamic targetKey;
    for (final entry in _userBox.toMap().entries) {
      final UserModel u = entry.value as UserModel;
      if (u.userId == userId) {
        targetKey = entry.key;
        break;
      }
    }
    if (targetKey != null) {
      await _userBox.delete(targetKey);
      notifyListeners();
    }

    if (antrianRepo != null) {
      await antrianRepo.deleteByDokterId(userId);
    } else {
      final antrianBox = Hive.box('antrianBox');
      final entries = antrianBox
          .toMap()
          .entries
          .where((e) => (e.value as dynamic).dokterId == userId)
          .toList();
      for (final e in entries) await antrianBox.delete(e.key);
    }
  }
}
