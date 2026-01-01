// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obat_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ObatModelAdapter extends TypeAdapter<ObatModel> {
  @override
  final int typeId = 6;

  @override
  ObatModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ObatModel(
      obatId: fields[0] as String,
      namaObat: fields[1] as String,
      satuan: fields[2] as String,
      stokSaatIni: fields[3] as int,
      hargaJual: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ObatModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.obatId)
      ..writeByte(1)
      ..write(obj.namaObat)
      ..writeByte(2)
      ..write(obj.satuan)
      ..writeByte(3)
      ..write(obj.stokSaatIni)
      ..writeByte(4)
      ..write(obj.hargaJual);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObatModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
