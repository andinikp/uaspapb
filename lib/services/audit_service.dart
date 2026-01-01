import 'package:hive/hive.dart';
import '../models/audit_model.dart';

class AuditService {
  static const String boxName = 'auditBox';

  /// Adds an audit log entry. Safe to call anywhere; if the box is not open
  /// or operation fails, it swallows exceptions to avoid blocking main flows.
  static Future<void> log(
    String action,
    String details, {
    String? userId,
    String level = 'INFO',
  }) async {
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      final box = Hive.box<AuditModel>(boxName);
      final entry = AuditModel(
        timestamp: DateTime.now(),
        level: level,
        userId: userId,
        action: action,
        details: details,
      );
      await box.add(entry);
    } catch (_) {
      // intentionally ignore to avoid breaking caller flows
    }
  }
}
