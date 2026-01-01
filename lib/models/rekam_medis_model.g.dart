// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rekam_medis_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RekamMedisModelAdapter extends TypeAdapter<RekamMedisModel> {
  @override
  final int typeId = 5;

  @override
  RekamMedisModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RekamMedisModel(
      rmId: fields[0] as String,
      antrianId: fields[1] as String,
      pasienId: fields[2] as String,
      dokterId: fields[3] as String,
      tanggalPeriksa: fields[4] as DateTime,
      keluhan: fields[5] as String,
      diagnosa: fields[6] as String,
      tindakan: fields[7] as String,
      membutuhkanResep: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RekamMedisModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.rmId)
      ..writeByte(1)
      ..write(obj.antrianId)
      ..writeByte(2)
      ..write(obj.pasienId)
      ..writeByte(3)
      ..write(obj.dokterId)
      ..writeByte(4)
      ..write(obj.tanggalPeriksa)
      ..writeByte(5)
      ..write(obj.keluhan)
      ..writeByte(6)
      ..write(obj.diagnosa)
      ..writeByte(7)
      ..write(obj.tindakan)
      ..writeByte(8)
      ..write(obj.membutuhkanResep);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RekamMedisModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
