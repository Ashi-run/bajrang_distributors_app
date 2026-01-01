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

  // --- DUPLICATE CHECKS ---
  
  bool checkCustomerExists(String name) {
    final list = _customerBox.values.toList();
    return list.any((c) => c.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  // Returns TRUE if a product with exact Name + Group + Category already exists
  bool checkProductExists(String name, String group, String category) {
    final list = _productBox.values.toList();
    return list.any((p) => 
      p.name.trim().toLowerCase() == name.trim().toLowerCase() &&
      p.group.trim().toLowerCase() == group.trim().toLowerCase() &&
      p.category.trim().toLowerCase() == category.trim().toLowerCase()
    );
  }

  // --- SMART PRICE RESOLVER ---
  double getEffectivePrice(ProductModel product, String? customerName, String targetUom) {
    final allOrders = _orderBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); 

    double factor = ProductModel.toDoubleSafe(product.conversionFactor);
    if (factor <= 0) factor = 1.0;

    double convertPrice(double price, String fromUom, String toUom) {
      if (fromUom == toUom) return price;
      if (fromUom == product.uom && toUom == product.secondaryUom) return price * factor;
      if (fromUom == product.secondaryUom && toUom == product.uom) return price / factor;
      return price; 
    }

    if (customerName != null && customerName.isNotEmpty) {
      final customerOrders = allOrders.where((o) => o.customerName.trim().toLowerCase() == customerName.trim().toLowerCase());
      for (var order in customerOrders) {
        for (var item in order.items) {
           if ((item.product.id == product.id || item.product.name == product.name) && item.uom == targetUom) {
             return item.sellPrice; 
           }
        }
      }
      for (var order in customerOrders) {
        for (var item in order.items) {
           if (item.product.id == product.id || item.product.name == product.name) {
             return convertPrice(item.sellPrice, item.uom, targetUom);
           }
        }
      }
    }

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

    double pPrice = ProductModel.toDoubleSafe(product.price);    
    double pPrice2 = ProductModel.toDoubleSafe(product.price2);  

    if (targetUom == product.secondaryUom) {
       if (pPrice2 > 0) return pPrice2;              
       if (pPrice > 0) return pPrice * factor;      
    }
    
    if (targetUom == product.uom) {
       if (pPrice2 > 0 && factor > 0) {
         return pPrice2 / factor; 
       }
       if (pPrice > 0) return pPrice;                
    }
    
    return pPrice;
  }

  // --- IMPORT EXCEL: PRODUCTS (WITH DUPLICATE CHECK) ---
  Future<String> importProductData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        final sheet = excel.tables[excel.tables.keys.first];
        
        int addedCount = 0;
        int skippedCount = 0;

        List<ProductModel> tempProductList = _productBox.values.toList();

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
            String group = safeVal(0);
            String category = safeVal(1);

            if (name.isEmpty) continue;

            // --- CHECK DUPLICATE ---
            bool exists = tempProductList.any((p) => 
               p.name.toLowerCase() == name.toLowerCase() &&
               p.group.toLowerCase() == group.toLowerCase() &&
               p.category.toLowerCase() == category.toLowerCase()
            );

            if (exists) {
              skippedCount++;
              continue; 
            }

            ProductModel p = ProductModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name,
              group: group,
              category: category,
              uom: safeVal(3).isEmpty ? "Pkt" : safeVal(3),
              price: safeDouble(4),
              image: safeVal(5),
              secondaryUom: safeVal(6).isEmpty ? null : safeVal(6),
              conversionFactor: safeDouble(7),
              price2: 0.0, 
            );
            
            await addProduct(p);
            tempProductList.add(p); 
            addedCount++;
          }
        }
        return "Imported: $addedCount, Skipped (Duplicate): $skippedCount";
      }
      return "No file selected";
    } catch (e) {
      return "Import Error: $e";
    }
  }

  // --- IMPORT EXCEL: CUSTOMERS (WITH DUPLICATE CHECK) ---
  Future<String> importCustomerData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        int addedCount = 0;
        int skippedCount = 0;
        
        List<CustomerModel> tempCustomerList = _customerBox.values.toList();

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

            // --- CHECK DUPLICATE ---
            bool exists = tempCustomerList.any((c) => c.name.toLowerCase() == name.toLowerCase());

            if (exists) {
              skippedCount++;
              continue;
            }

            String phone = safeVal(1);
            String address = safeVal(2);

            var newCust = CustomerModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name,
              phone: phone,
              address: address,
            );

            await addCustomer(newCust);
            tempCustomerList.add(newCust);
            addedCount++;
          }
        }
        return "Imported: $addedCount, Skipped (Duplicate): $skippedCount";
      }
      return "No file selected";
    } catch (e) {
      return "Error: $e";
    }
  }
  
  // BULK ACTIONS
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
}