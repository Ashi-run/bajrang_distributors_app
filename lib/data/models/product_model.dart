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

  // --- USE DYNAMIC TO PREVENT CRASHES ---
  @HiveField(5)
  final dynamic price; 

  @HiveField(6)
  final String image;

  @HiveField(7)
  final String? secondaryUom;

  @HiveField(8)
  final dynamic price2; 

  @HiveField(9)
  final dynamic conversionFactor; 

  @HiveField(10)
  final dynamic lastGlobalSoldPrice; 

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

  // --- STATIC HELPER: SAFELY CONVERT DATA TO DOUBLE ---
  static double toDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      String clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? group,
    String? category,
    String? uom,
    dynamic price,
    String? image,
    String? secondaryUom,
    dynamic price2,
    dynamic conversionFactor,
    dynamic lastGlobalSoldPrice,
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