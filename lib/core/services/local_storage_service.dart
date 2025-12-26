import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/cart_item_model.dart'; // This file contains the Adapter

class LocalStorageService {
  // UPDATE THESE STRINGS TO MATCH REPOSITORY
  static const String productBoxName = 'products_v2';
  static const String customerBoxName = 'customers_v2';
  static const String orderBoxName = 'orders_v2';
  static const String settingsBoxName = 'settings_v2'; // Assuming you want settings on v2 as well

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(CustomerModelAdapter());
    Hive.registerAdapter(OrderModelAdapter());
    Hive.registerAdapter(CartItemAdapter()); 

    // Open the V2 Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<CustomerModel>(customerBoxName);
    await Hive.openBox<OrderModel>(orderBoxName);
    await Hive.openBox(settingsBoxName);
  }
}