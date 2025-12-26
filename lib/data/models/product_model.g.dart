// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 1;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      group: fields[1] as String,
      category: fields[2] as String,
      name: fields[3] as String,
      uom: fields[4] as String,
      price: fields[5] as double,
      image: fields[6] as String,
      secondaryUom: fields[7] as String?,
      conversionFactor: fields[8] as int?,
      price2: fields[9] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.group)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.uom)
      ..writeByte(5)
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.image)
      ..writeByte(7)
      ..write(obj.secondaryUom)
      ..writeByte(8)
      ..write(obj.conversionFactor)
      ..writeByte(9)
      ..write(obj.price2);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
