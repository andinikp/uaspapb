import 'package:hive/hive.dart';
part 'audit_model.g.dart';

@HiveType(typeId: 9)
class AuditModel extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  String level; // e.g., INFO, WARN, ERROR

  @HiveField(2)
  String? userId;

  @HiveField(3)
  String action;

  @HiveField(4)
  String details;

  AuditModel({
    required this.timestamp,
    this.level = 'INFO',
    this.userId,
    required this.action,
    required this.details,
  });
}
