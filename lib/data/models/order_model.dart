import 'package:hive/hive.dart';
import 'cart_item_model.dart';

part 'order_model.g.dart';

@HiveType(typeId: 2)
class OrderModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerName;

  @HiveField(2)
  final String customerPhone;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final double totalAmount;

  @HiveField(5)
  final double discount;

  @HiveField(6)
  final List<CartItem> items;

  @HiveField(7) // <--- NEW FIELD
  bool isApproved; 

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.totalAmount,
    required this.discount,
    required this.items,
    this.isApproved = false, // Default is Pending
  });
}