import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import '../data/models/customer_model.dart';
import '../data/models/order_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  double get totalAmount => state.fold(0, (sum, item) => sum + item.total);

  // --- ADD ITEM ---
  void addItem(ProductModel product, CustomerModel? customer) {
    if (state.any((item) => item.product.id == product.id)) return;

    double finalPrice = product.price.toDouble(); // FIX: toDouble()
    bool foundPersonalHistory = false;

    if (customer != null && Hive.isBoxOpen('orders_v2')) {
      final orderBox = Hive.box<OrderModel>('orders_v2');
      final customerOrders = orderBox.values
          .where((o) => o.customerName.trim().toLowerCase() == customer.name.trim().toLowerCase())
          .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

      for (var order in customerOrders) {
        for (var item in order.items) {
           if (item.product.id == product.id || item.product.name == product.name) {
             finalPrice = item.sellPrice;
             foundPersonalHistory = true;
             break; 
           }
        }
        if (foundPersonalHistory) break;
      }
    }

    if (!foundPersonalHistory) {
      if (product.lastGlobalSoldPrice != null && product.lastGlobalSoldPrice! > 0) {
        finalPrice = product.lastGlobalSoldPrice!.toDouble(); // FIX: toDouble()
      }
    }

    state = [
      ...state,
      CartItem(
        product: product,
        quantity: 1,
        sellPrice: finalPrice,
        uom: product.uom,
        originalQty: 1,
        scheme: "", 
        discount: 0,
        remark: ""
      )
    ];
  }

  void updateQuantity(ProductModel product, int qty) {
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          CartItem(
            product: item.product,
            quantity: qty,
            sellPrice: item.sellPrice,
            uom: item.uom,
            discount: item.discount,
            scheme: item.scheme,
            originalQty: qty,
            remark: item.remark
          )
        else item
    ];
    state = state.where((item) => item.quantity > 0).toList();
  }

  void updatePrice(ProductModel product, double price) {
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          CartItem(
            product: item.product,
            quantity: item.quantity,
            sellPrice: price,
            uom: item.uom,
            discount: item.discount,
            scheme: item.scheme,
            originalQty: item.originalQty,
            remark: item.remark
          )
        else item
    ];
  }

  void updateUom(ProductModel product, String newUom) {
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          CartItem(
            product: item.product,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            uom: newUom,
            discount: item.discount,
            scheme: item.scheme,
            originalQty: item.originalQty,
            remark: item.remark
          )
        else item
    ];
  }

  void updateUomAndPrice(ProductModel product, String newUom, double newPrice) {
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          CartItem(
            product: item.product,
            quantity: item.quantity,
            sellPrice: newPrice,
            uom: newUom,
            discount: item.discount,
            scheme: item.scheme,
            originalQty: item.originalQty,
            remark: item.remark
          )
        else item
    ];
  }

  void updateScheme(ProductModel product, String scheme) {
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          CartItem(
            product: item.product,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            uom: item.uom,
            discount: item.discount,
            scheme: scheme,
            originalQty: item.originalQty,
            remark: item.remark
          )
        else item
    ];
  }

  void updateDiscount(ProductModel product, double discount) {
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          CartItem(
            product: item.product,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            uom: item.uom,
            discount: discount,
            scheme: item.scheme,
            originalQty: item.originalQty,
            remark: item.remark
          )
        else item
    ];
  }

  void decreaseItem(ProductModel product) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index != -1) {
      if (state[index].quantity > 1) {
        updateQuantity(product, state[index].quantity - 1);
      } else {
        state = state.where((i) => i.product.id != product.id).toList();
      }
    }
  }

  void clearCart() {
    state = [];
  }
}