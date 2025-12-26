import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/product_model.dart';
import 'data/models/customer_model.dart';
import 'data/models/order_model.dart';
import 'data/models/cart_item_model.dart';
import 'views/dashboard/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapters
  try {
    Hive.registerAdapter(CustomerModelAdapter());
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(OrderModelAdapter());
    Hive.registerAdapter(CartItemAdapter());
  } catch (e) {
    debugPrint("Adapter Error (Ignore if already registered): $e");
  }

  // Open Boxes
  await Hive.openBox<ProductModel>('products_v2');
  await Hive.openBox<CustomerModel>('customers_v2');
  await Hive.openBox<OrderModel>('orders_v2');
  await Hive.openBox('settings_v2');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bajrang Distributors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: DashboardView(), // FIX: No 'const' keyword
    );
  }
}