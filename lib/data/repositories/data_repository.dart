import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';

class DataRepository {
  final Box<ProductModel> _productBox = Hive.box<ProductModel>('products_v2');
  final Box<CustomerModel> _customerBox = Hive.box<CustomerModel>('customers_v2');
  final Box<OrderModel> _orderBox = Hive.box<OrderModel>('orders_v2');

  List<ProductModel> getAllProducts() => _productBox.values.toList();
  List<CustomerModel> getAllCustomers() => _customerBox.values.toList();
  List<OrderModel> getAllOrders() => _orderBox.values.toList();

  Future<void> addProduct(ProductModel product) async => await _productBox.put(product.id, product);
  Future<void> updateProduct(ProductModel product) async => await _productBox.put(product.id, product);
  Future<void> deleteProduct(String id) async => await _productBox.delete(id);

  Future<void> addCustomer(CustomerModel customer) async => await _customerBox.put(customer.id, customer);
  Future<void> updateCustomer(CustomerModel customer) async => await _customerBox.put(customer.id, customer);
  Future<void> deleteCustomer(String id) async => await _customerBox.delete(id);

  Future<void> addOrder(OrderModel order) async {
    await _orderBox.put(order.id, order);
    for (var item in order.items) {
      ProductModel? product = _productBox.get(item.product.id);
      if (product != null && item.sellPrice > 0) {
        final updated = product.copyWith(lastGlobalSoldPrice: item.sellPrice);
        await _productBox.put(product.id, updated);
      }
    }
  }
  
  Future<void> updateOrder(OrderModel order) async => await _orderBox.put(order.id, order);
  Future<void> deleteOrder(String id) async => await _orderBox.delete(id);

  // --- SMART PRICE RESOLVER ---
  double getEffectivePrice(ProductModel product, String? customerName, String targetUom) {
    final allOrders = _orderBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); 

    double factor = ProductModel.toDoubleSafe(product.conversionFactor);
    if (factor <= 0) factor = 1.0;

    // Helper: Convert price
    double convertPrice(double price, String fromUom, String toUom) {
      if (fromUom == toUom) return price;
      if (fromUom == product.uom && toUom == product.secondaryUom) return price * factor;
      if (fromUom == product.secondaryUom && toUom == product.uom) return price / factor;
      return price; 
    }

    // 1. CHECK CUSTOMER HISTORY
    if (customerName != null && customerName.isNotEmpty) {
      final customerOrders = allOrders.where((o) => o.customerName.trim().toLowerCase() == customerName.trim().toLowerCase());
      // Priority 1A: Exact Match
      for (var order in customerOrders) {
        for (var item in order.items) {
           if ((item.product.id == product.id || item.product.name == product.name) && item.uom == targetUom) {
             return item.sellPrice; 
           }
        }
      }
      // Priority 1B: Convert Match
      for (var order in customerOrders) {
        for (var item in order.items) {
           if (item.product.id == product.id || item.product.name == product.name) {
             return convertPrice(item.sellPrice, item.uom, targetUom);
           }
        }
      }
    }

    // 2. CHECK GLOBAL HISTORY
    for (var order in allOrders) {
      for (var item in order.items) {
         if ((item.product.id == product.id || item.product.name == product.name) && item.uom == targetUom) {
           return item.sellPrice; 
         }
      }
    }
    for (var order in allOrders) {
      for (var item in order.items) {
         if (item.product.id == product.id || item.product.name == product.name) {
           return convertPrice(item.sellPrice, item.uom, targetUom);
         }
      }
    }

    // --- 3. MASTER LIST PRICE (LOGIC UPDATED) ---
    double pPrice = ProductModel.toDoubleSafe(product.price);    // Base Price (e.g., Jar)
    double pPrice2 = ProductModel.toDoubleSafe(product.price2);  // Sec Price (e.g., Ctn)

    // A. If target is Secondary (e.g. Ctn)
    if (targetUom == product.secondaryUom) {
       // If Ctn price exists, use it. If not, calculate from Jar.
       if (pPrice2 > 0) return pPrice2;              
       if (pPrice > 0) return pPrice * factor; // Fix for 40 -> 1600      
    }
    
    // B. If target is Base (e.g. Jar)
    if (targetUom == product.uom) {
       // Fix for 150 vs 146: If Ctn price exists (4400), derive Jar from it (4400/30 = 146)
       if (pPrice2 > 0 && factor > 0) {
         return pPrice2 / factor; 
       }
       // Fallback to explicit Jar price only if Ctn price is missing
       if (pPrice > 0) return pPrice;                
    }
    
    return pPrice;
  }

  // --- IMPORT EXCEL ---
  Future<void> importProductData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        final sheet = excel.tables[excel.tables.keys.first];
        if (sheet != null) {
          for (var i = 1; i < sheet.rows.length; i++) {
            List<dynamic> row = sheet.rows[i];
            if (row.isEmpty) continue;

            String safeVal(int index) {
               if (index >= row.length || row[index] == null) return "";
               var cell = row[index];
               return cell?.value?.toString().trim() ?? "";
            }
            
            double safeDouble(int index) {
               if (index >= row.length || row[index] == null) return 0.0;
               var cell = row[index];
               var val = cell?.value; 
               if (val == null) return 0.0;
               if (val is double) return val;
               if (val is int) return val.toDouble();
               return double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            }

            String name = safeVal(2);
            if (name.isEmpty) continue;

            ProductModel p = ProductModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name,
              group: safeVal(0),
              category: safeVal(1),
              uom: safeVal(3).isEmpty ? "Pkt" : safeVal(3),
              price: safeDouble(4),
              image: safeVal(5),
              secondaryUom: safeVal(6).isEmpty ? null : safeVal(6),
              conversionFactor: safeDouble(7),
              price2: 0.0, 
            );
            await addProduct(p);
          }
        }
      }
    } catch (e) {
      debugPrint("Import Error: $e");
    }
  }

  // --- BULK ACTIONS ---
  Future<void> renameGroup(String oldName, String newName) async {
    final products = getAllProducts().where((p) => p.group == oldName).toList();
    for (var p in products) await updateProduct(p.copyWith(group: newName));
  }
  Future<void> deleteGroup(String name) async {
    final products = getAllProducts().where((p) => p.group == name).toList();
    for (var p in products) await deleteProduct(p.id);
  }
  Future<void> renameCategory(String g, String oldC, String newC) async {
    final products = getAllProducts().where((p) => p.group == g && p.category == oldC).toList();
    for (var p in products) await updateProduct(p.copyWith(category: newC));
  }
  Future<void> deleteCategory(String g, String c) async {
    final products = getAllProducts().where((p) => p.group == g && p.category == c).toList();
    for (var p in products) await deleteProduct(p.id);
  }

  // --- IMPORT EXCEL: CUSTOMERS ---
  Future<String> importCustomerData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls'],
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
            
            String safeVal(int index) {
               if (index >= row.length || row[index] == null) return "";
               return row[index]!.value.toString().trim();
            }

            String name = safeVal(0);
            if (name.isEmpty) continue;

            String phone = safeVal(1);
            String address = safeVal(2);

            await addCustomer(CustomerModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name,
              phone: phone,
              address: address,
            ));
            count++;
          }
        }
        return "Imported $count customers";
      }
      return "No file selected";
    } catch (e) {
      return "Error: $e";
    }
  }
}