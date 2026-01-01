// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pasien_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasienModelAdapter extends TypeAdapter<PasienModel> {
  @override
  final int typeId = 2;

  @override
  PasienModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasienModel(
      pasienId: fields[0] as String,
      namaPasien: fields[1] as String,
      nik: fields[2] as String,
      tglLahir: fields[3] as DateTime,
      alamat: fields[4] as String,
      noTelp: fields[5] as String,
      jenisKelamin: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PasienModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.pasienId)
      ..writeByte(1)
      ..write(obj.namaPasien)
      ..writeByte(2)
      ..write(obj.nik)
      ..writeByte(3)
      ..write(obj.tglLahir)
      ..writeByte(4)
      ..write(obj.alamat)
      ..writeByte(5)
      ..write(obj.noTelp)
      ..writeByte(6)
      ..write(obj.jenisKelamin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasienModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
