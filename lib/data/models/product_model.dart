import 'package:hive/hive.dart';

part 'product_model.g.dart'; // Ensure you run: flutter pub run build_runner build

@HiveType(typeId: 1)
class ProductModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  // REMOVED VARIANT FIELD (HiveField 2 was likely variant, skipping it is fine or renumbering)

  @HiveField(3)
  final String group;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final double price;

  @HiveField(6)
  final double? price2;

  @HiveField(7)
  final String uom;

  @HiveField(8)
  final String? secondaryUom;

  @HiveField(9)
  final int? conversionFactor;

  @HiveField(10)
  final String image;

  ProductModel({
    required this.id,
    required this.name,
    // Removed variant
    required this.group,
    required this.category,
    required this.price,
    this.price2,
    required this.uom,
    this.secondaryUom,
    this.conversionFactor,
    required this.image,
  });
}