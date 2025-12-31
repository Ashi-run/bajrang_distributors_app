import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 1)
class ProductModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String group;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String uom;

  @HiveField(5)
  final double price; // Default Master Price

  @HiveField(6)
  final String image;

  @HiveField(7)
  final String? secondaryUom;

  @HiveField(8)
  final double? price2;

  @HiveField(9)
  final double? conversionFactor;
  
  // --- NEW FIELD: Priority 2 (Global Last Sold Price) ---
  @HiveField(10)
  final double? lastGlobalSoldPrice; 

  ProductModel({
    required this.id,
    required this.name,
    required this.group,
    required this.category,
    required this.uom,
    required this.price,
    required this.image,
    this.secondaryUom,
    this.price2,
    this.conversionFactor,
    this.lastGlobalSoldPrice,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? group,
    String? category,
    String? uom,
    double? price,
    String? image,
    String? secondaryUom,
    double? price2,
    double? conversionFactor,
    double? lastGlobalSoldPrice,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      category: category ?? this.category,
      uom: uom ?? this.uom,
      price: price ?? this.price,
      image: image ?? this.image,
      secondaryUom: secondaryUom ?? this.secondaryUom,
      price2: price2 ?? this.price2,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      lastGlobalSoldPrice: lastGlobalSoldPrice ?? this.lastGlobalSoldPrice,
    );
  }
}