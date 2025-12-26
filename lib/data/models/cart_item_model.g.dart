// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 3;

  @override
  CartItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItem(
      product: fields[0] as ProductModel,
      quantity: fields[1] as int,
      sellPrice: fields[2] as double,
      scheme: fields[3] as String,
      discount: fields[4] as double,
      remark: fields[5] as String,
      uom: fields[6] as String,
      isAccepted: fields[7] as bool,
      originalQty: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.sellPrice)
      ..writeByte(3)
      ..write(obj.scheme)
      ..writeByte(4)
      ..write(obj.discount)
      ..writeByte(5)
      ..write(obj.remark)
      ..writeByte(6)
      ..write(obj.uom)
      ..writeByte(7)
      ..write(obj.isAccepted)
      ..writeByte(8)
      ..write(obj.originalQty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
