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

  // TOTAL CALCULATION
  double get totalAmount => state.fold(0, (sum, item) => sum + item.total);

  // --- ADD ITEM (WITH ADVANCED PRICING LOGIC) ---
  void addItem(ProductModel product, CustomerModel? customer) {
    // 1. Check if item is already in cart
    if (state.any((item) => item.product.id == product.id)) {
      return; // Already in cart, do nothing (or increment qty if you prefer)
    }

    // 2. Determine Rate based on Priority
    double finalPrice = product.price; // Default: Priority 3 (Master Price)
    
    // Priority 1: Customer Specific History
    bool foundPersonalHistory = false;
    if (customer != null && Hive.isBoxOpen('orders_v2')) {
      final orderBox = Hive.box<OrderModel>('orders_v2');
      
      // Get orders for this customer
      final customerOrders = orderBox.values
          .where((o) => o.customerName.trim().toLowerCase() == customer.name.trim().toLowerCase())
          .toList();
          
      // Sort newest first
      customerOrders.sort((a, b) => b.date.compareTo(a.date));

      // Look for the last time they bought THIS product
      for (var order in customerOrders) {
        // Check items in that order
        for (var item in order.items) {
           // Check by ID or Name (Name is safer if IDs change on re-import)
           if (item.product.id == product.id || item.product.name == product.name) {
             finalPrice = item.sellPrice;
             foundPersonalHistory = true;
             break; 
           }
        }
        if (foundPersonalHistory) break;
      }
    }

    // Priority 2: Global Last Sold Price (Only if no personal history found)
    if (!foundPersonalHistory) {
      if (product.lastGlobalSoldPrice != null && product.lastGlobalSoldPrice! > 0) {
        finalPrice = product.lastGlobalSoldPrice!;
      }
    }

    // 3. Add to Cart with calculated price
    state = [
      ...state,
      CartItem(
        product: product,
        quantity: 1,
        sellPrice: finalPrice, // <--- Auto-filled Rate
        uom: product.uom,
        originalQty: 1,
        scheme: "", 
        discount: 0,
        remark: ""
      )
    ];
  }

  // UPDATE QUANTITY
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
            originalQty: qty, // Sync original
            remark: item.remark
          )
        else
          item
    ];
    // Remove items with 0 quantity
    state = state.where((item) => item.quantity > 0).toList();
  }

  // UPDATE SCHEME
  void updateScheme(ProductModel product, String schemeText) {
    state = [
      for (final item in state)
        if (item.product.id == product.id)
          CartItem(
            product: item.product,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            uom: item.uom,
            discount: item.discount,
            scheme: schemeText,
            originalQty: item.originalQty,
            remark: item.remark
          )
        else
          item
    ];
  }

  // UPDATE PRICE
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
        else
          item
    ];
  }

  // UPDATE DISCOUNT
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
        else
          item
    ];
  }

  // UPDATE UOM & PRICE
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
        else
          item
    ];
  }
  
  // UPDATE UOM ONLY
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
        else
          item
    ];
  }

  // DECREASE ITEM
  void decreaseItem(ProductModel product) {
    // Find item or return dummy
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index == -1) return;

    final existing = state[index];
    
    if (existing.quantity > 1) {
      updateQuantity(product, existing.quantity - 1);
    } else {
      state = state.where((i) => i.product.id != product.id).toList();
    }
  }

  void clearCart() {
    state = [];
  }
}