import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/audit_model.dart';

class AuditRepository extends ChangeNotifier {
  static const String boxName = 'auditBox';

  Box<AuditModel> get _box => Hive.box<AuditModel>(boxName);

  Future<void> addLog(AuditModel entry) async {
    await _box.add(entry);
    notifyListeners();
  }

  List<AuditModel> getAll() {
    return _box.values.toList().cast<AuditModel>();
  }

  List<AuditModel> getByRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return getAll()
        .where(
          (r) =>
              r.timestamp.isAfter(s.subtract(const Duration(seconds: 1))) &&
              r.timestamp.isBefore(e.add(const Duration(seconds: 1))),
        )
        .toList();
  }
}
