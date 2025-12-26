import 'package:hive/hive.dart';
import 'product_model.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 3)
class CartItem {
  @HiveField(0)
  final ProductModel product;
  @HiveField(1)
  final int quantity;
  @HiveField(2)
  final double sellPrice; // Edited Rate
  
  @HiveField(3)
  final String scheme; // CHANGED FROM INT TO STRING (e.g. "1+1 Free")
  
  @HiveField(4)
  final double discount;
  @HiveField(5)
  final String remark;
  @HiveField(6)
  final String uom;
  @HiveField(7)
  final bool isAccepted;
  @HiveField(8)
  final int originalQty;

  CartItem({
    required this.product,
    required this.quantity,
    required this.sellPrice,
    this.scheme = "", // Default empty text
    this.discount = 0.0,
    this.remark = "",
    required this.uom,
    this.isAccepted = true,
    required this.originalQty,
  });

  double get total => (quantity * sellPrice) - discount;
}