// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'antrian_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AntrianModelAdapter extends TypeAdapter<AntrianModel> {
  @override
  final int typeId = 4;

  @override
  AntrianModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AntrianModel(
      antrianId: fields[0] as String,
      pasienId: fields[1] as String,
      dokterId: fields[2] as String,
      nomorAntrian: fields[3] as int,
      status: fields[4] as AntrianStatus,
      waktuMasuk: fields[5] as DateTime,
      sudahDibayar: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AntrianModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.antrianId)
      ..writeByte(1)
      ..write(obj.pasienId)
      ..writeByte(2)
      ..write(obj.dokterId)
      ..writeByte(3)
      ..write(obj.nomorAntrian)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.waktuMasuk)
      ..writeByte(6)
      ..write(obj.sudahDibayar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AntrianModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AntrianStatusAdapter extends TypeAdapter<AntrianStatus> {
  @override
  final int typeId = 3;

  @override
  AntrianStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AntrianStatus.menunggu;
      case 1:
        return AntrianStatus.diperiksa;
      case 2:
        return AntrianStatus.selesai;
      case 3:
        return AntrianStatus.menungguObat;
      default:
        return AntrianStatus.menunggu;
    }
  }

  @override
  void write(BinaryWriter writer, AntrianStatus obj) {
    switch (obj) {
      case AntrianStatus.menunggu:
        writer.writeByte(0);
        break;
      case AntrianStatus.diperiksa:
        writer.writeByte(1);
        break;
      case AntrianStatus.selesai:
        writer.writeByte(2);
        break;
      case AntrianStatus.menungguObat:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AntrianStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
