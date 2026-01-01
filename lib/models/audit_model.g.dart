// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditModelAdapter extends TypeAdapter<AuditModel> {
  @override
  final int typeId = 9;

  @override
  AuditModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditModel(
      timestamp: fields[0] as DateTime,
      level: fields[1] as String,
      userId: fields[2] as String?,
      action: fields[3] as String,
      details: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuditModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.details);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
