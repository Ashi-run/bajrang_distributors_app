import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // TOTAL CALCULATION
  double get totalAmount => state.fold(0, (sum, item) => sum + item.total);

  // ADD ITEM
  void addItem(ProductModel product) {
    if (!state.any((item) => item.product.id == product.id)) {
      state = [
        ...state,
        CartItem(
          product: product,
          quantity: 1,
          sellPrice: product.price,
          uom: product.uom,
          originalQty: 1, // Init matches Quantity
          scheme: "", 
          discount: 0,
          remark: ""
        )
      ];
    }
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
            originalQty: qty, // FIX: SYNC ORIGINAL QTY WITH CART QTY
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
            originalQty: item.originalQty, // Keep synced
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
    final existing = state.firstWhere((i) => i.product.id == product.id, orElse: () => CartItem(product: product, quantity: 0, sellPrice: 0, uom: '', originalQty: 0));
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