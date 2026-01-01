// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resep_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResepDetailModelAdapter extends TypeAdapter<ResepDetailModel> {
  @override
  final int typeId = 7;

  @override
  ResepDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResepDetailModel(
      obatId: fields[0] as String,
      namaObat: fields[1] as String,
      jumlah: fields[2] as int,
      hargaSatuan: fields[3] as double,
      aturanPakai: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ResepDetailModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.obatId)
      ..writeByte(1)
      ..write(obj.namaObat)
      ..writeByte(2)
      ..write(obj.jumlah)
      ..writeByte(3)
      ..write(obj.hargaSatuan)
      ..writeByte(4)
      ..write(obj.aturanPakai);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResepDetailModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ResepModelAdapter extends TypeAdapter<ResepModel> {
  @override
  final int typeId = 8;

  @override
  ResepModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResepModel(
      resepId: fields[0] as String,
      rmId: fields[1] as String,
      pasienId: fields[2] as String,
      tanggalResep: fields[3] as DateTime,
      detailObat: (fields[4] as List).cast<ResepDetailModel>(),
      isDisiapkan: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ResepModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.resepId)
      ..writeByte(1)
      ..write(obj.rmId)
      ..writeByte(2)
      ..write(obj.pasienId)
      ..writeByte(3)
      ..write(obj.tanggalResep)
      ..writeByte(4)
      ..write(obj.detailObat)
      ..writeByte(5)
      ..write(obj.isDisiapkan);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResepModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
