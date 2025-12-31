import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';

class DataRepository {
  // Boxes
  final Box<ProductModel> _productBox = Hive.box<ProductModel>('products_v2');
  final Box<CustomerModel> _customerBox = Hive.box<CustomerModel>('customers_v2');
  final Box<OrderModel> _orderBox = Hive.box<OrderModel>('orders_v2');

  // --- PRODUCTS ---
  List<ProductModel> getAllProducts() {
    return _productBox.values.toList();
  }

  Future<void> addProduct(ProductModel product) async {
    await _productBox.put(product.id, product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _productBox.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    await _productBox.delete(id);
  }

  // --- CUSTOMERS ---
  List<CustomerModel> getAllCustomers() {
    return _customerBox.values.toList();
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await _customerBox.put(customer.id, customer);
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _customerBox.put(customer.id, customer);
  }

  Future<void> deleteCustomer(String id) async {
    await _customerBox.delete(id);
  }

  // --- ORDERS ---
  List<OrderModel> getAllOrders() {
    return _orderBox.values.toList();
  }

  // --- PRICE RESOLVER LOGIC (UNIT STRICT) ---
  double getEffectivePrice(ProductModel product, String? customerName, String currentUom) {
    // 1. Get all orders, sorted newest first
    final allOrders = _orderBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Priority 1: Customer Specific History (Must match Product + UOM)
    if (customerName != null && customerName.isNotEmpty) {
      for (var order in allOrders) {
        if (order.customerName.trim().toLowerCase() == customerName.trim().toLowerCase()) {
          for (var item in order.items) {
             if ((item.product.id == product.id || item.product.name == product.name) && 
                 item.uom == currentUom) {
               return item.sellPrice; 
             }
          }
        }
      }
    }

    // Priority 2: Global Last Sold Price (Must match Product + UOM)
    for (var order in allOrders) {
      for (var item in order.items) {
         if ((item.product.id == product.id || item.product.name == product.name) && 
             item.uom == currentUom) {
           return item.sellPrice; 
         }
      }
    }

    // Priority 3: Default Master Price
    // If secondary unit is selected, try to return secondary price
    if (currentUom == product.secondaryUom) {
       // If a specific secondary price exists, use it
       if (product.price2 != null && product.price2! > 0) {
         return product.price2!;
       }
       // Otherwise, Auto-Convert: Price1 * Factor
       if (product.conversionFactor != null && product.conversionFactor! > 0) {
         return product.price * product.conversionFactor!;
       }
    }
    
    return product.price;
  }

  Future<void> addOrder(OrderModel order) async {
    await _orderBox.put(order.id, order);
  }

  Future<void> updateOrder(OrderModel order) async {
    await _orderBox.put(order.id, order);
  }

  Future<void> deleteOrder(String id) async {
    await _orderBox.delete(id);
  }
  
  // --- BULK ACTIONS ---
  Future<void> renameGroup(String oldName, String newName) async {
    final products = getAllProducts().where((p) => p.group == oldName).toList();
    for (var p in products) {
      final updated = p.copyWith(group: newName);
      await updateProduct(updated);
    }
  }

  Future<void> deleteGroup(String groupName) async {
    final products = getAllProducts().where((p) => p.group == groupName).toList();
    for (var p in products) {
      await deleteProduct(p.id);
    }
  }

  Future<void> renameCategory(String groupName, String oldCat, String newCat) async {
    final products = getAllProducts().where((p) => p.group == groupName && p.category == oldCat).toList();
    for (var p in products) {
      final updated = p.copyWith(category: newCat);
      await updateProduct(updated);
    }
  }

  Future<void> deleteCategory(String groupName, String catName) async {
    final products = getAllProducts().where((p) => p.group == groupName && p.category == catName).toList();
    for (var p in products) {
      await deleteProduct(p.id);
    }
  }

  // --- IMPORT EXCEL (PRODUCTS) - FIXED & IMPROVED ---
  Future<void> importProductData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          // Start loop from row 1 (skipping header)
          for (int i = 1; i < sheet.rows.length; i++) {
            List<dynamic> row = sheet.rows[i];
            
            // 1. SMART EMPTY ROW CHECK
            // If row is empty, or Group(0) and Name(2) are both null/empty -> SKIP
            if (row.isEmpty) continue;
            
            String group = row.length > 0 ? row[0]?.value?.toString().trim() ?? "" : "";
            String name = row.length > 2 ? row[2]?.value?.toString().trim() ?? "" : "";

            // If neither group nor name exists, it's a blank row
            if (group.isEmpty && name.isEmpty) continue;

            String category = row.length > 1 ? row[1]?.value?.toString().trim() ?? "" : "";
            String uom = row.length > 3 ? row[3]?.value?.toString().trim() ?? "Pcs" : "Pcs";
            
            // 2. PARSE PRICE
            double price = 0.0;
            if (row.length > 4) {
              var pVal = row[4]?.value;
              if (pVal is num) price = pVal.toDouble();
              else if (pVal is String) price = double.tryParse(pVal) ?? 0.0;
            }

            // 3. SECONDARY UNIT & FACTOR LOGIC
            String? uom2;
            double? price2;
            double? conv; 
            
            // Column 6: Secondary Unit (e.g. "Bag", "Ctn")
            if (row.length > 6) {
               var u2 = row[6]?.value?.toString().trim();
               if (u2 != null && u2.isNotEmpty && u2.toLowerCase() != "null") {
                 uom2 = u2;
               }
            }

            // Column 7: Description / Conversion Factor (e.g. "40", "12")
            // We strip any text and take the number: "12 pcs" -> 12.0
            if (row.length > 7) {
               var cVal = row[7]?.value?.toString();
               if (cVal != null && cVal.isNotEmpty) {
                 // Remove anything that isn't a digit or decimal point
                 String cleanNum = cVal.replaceAll(RegExp(r'[^0-9.]'), '');
                 conv = double.tryParse(cleanNum);
               }
            }
            
            // Auto-Calculate Price2 if missing but Factor exists
            // Logic: 1 Bag = 40 Kg. If Kg Price = 100, Bag Price = 4000.
            if (conv != null && conv > 0 && price > 0) {
               price2 = price * conv;
            }

            ProductModel p = ProductModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name.isEmpty ? "Unknown Item" : name,
              group: group,
              category: category,
              uom: uom,
              price: price,
              secondaryUom: uom2,
              price2: price2,
              conversionFactor: conv,
              image: '', 
            );

            await addProduct(p);
          }
        }
      }
    } catch (e) {
      debugPrint("Error importing Excel: $e");
    }
  }

  // --- IMPORT EXCEL (CUSTOMERS) ---
  Future<String> importCustomerData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        int count = 0;

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          for (int i = 1; i < sheet.rows.length; i++) {
            List<dynamic> row = sheet.rows[i];
            
            if (row.isEmpty) continue;
            String name = row.length > 0 ? row[0]?.value?.toString().trim() ?? "" : "";
            
            if (name.isEmpty) continue;

            String phone = "";
            String address = "";

            if (row.length > 1) phone = row[1]?.value?.toString() ?? "";
            if (row.length > 2) address = row[2]?.value?.toString() ?? "";

            CustomerModel c = CustomerModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name,
              phone: phone,
              address: address,
            );

            await addCustomer(c);
            count++;
          }
        }
        return "Successfully imported $count customers!";
      }
      return "No file selected.";
    } catch (e) {
      return "Error importing: $e";
    }
  }
}