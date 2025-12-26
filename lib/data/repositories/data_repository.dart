import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../../core/services/excel_service.dart';

class DataRepository {
  final Box<ProductModel> _productBox = Hive.box<ProductModel>('products_v2');
  final Box<CustomerModel> _customerBox = Hive.box<CustomerModel>('customers_v2');
  final ExcelService _excelService = ExcelService();

  // =========================================================
  // PRODUCT METHODS
  // =========================================================

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

  Future<void> importProductData() async {
    List<ProductModel> newProducts = await _excelService.pickAndParseExcel();
    if (newProducts.isNotEmpty) {
      for (var p in newProducts) {
        await _productBox.put(p.id, p);
      }
    }
  }

  Future<void> renameGroup(String oldName, String newName) async {
    final products = _productBox.values.where((p) => p.group == oldName).toList();
    for (var p in products) {
      final updated = ProductModel(
        id: p.id,
        name: p.name, 
        group: newName, 
        category: p.category,
        price: p.price,
        price2: p.price2,
        uom: p.uom,
        secondaryUom: p.secondaryUom,
        conversionFactor: p.conversionFactor,
        image: p.image
      );
      await _productBox.put(p.id, updated);
    }
  }

  Future<void> renameCategory(String groupName, String oldCat, String newCat) async {
    final products = _productBox.values.where((p) => p.group == groupName && p.category == oldCat).toList();
    for (var p in products) {
      final updated = ProductModel(
        id: p.id,
        name: p.name,
        group: p.group,
        category: newCat,
        price: p.price,
        price2: p.price2,
        uom: p.uom,
        secondaryUom: p.secondaryUom,
        conversionFactor: p.conversionFactor,
        image: p.image
      );
      await _productBox.put(p.id, updated);
    }
  }

  Future<void> deleteGroup(String groupName) async {
    final keys = _productBox.values.where((p) => p.group == groupName).map((p) => p.id).toList();
    await _productBox.deleteAll(keys);
  }

  Future<void> deleteCategory(String groupName, String categoryName) async {
    final keys = _productBox.values.where((p) => p.group == groupName && p.category == categoryName).map((p) => p.id).toList();
    await _productBox.deleteAll(keys);
  }

  // =========================================================
  // CUSTOMER METHODS
  // =========================================================

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

  // UPDATED: Now calls real logic instead of placeholder
  Future<String> importCustomerData() async {
    List<CustomerModel> newCustomers = await _excelService.pickAndParseCustomers();
    
    if (newCustomers.isNotEmpty) {
      int count = 0;
      for (var c in newCustomers) {
        // Prevent exact duplicates by checking name (Optional but safer)
        bool exists = _customerBox.values.any((existing) => existing.name.toLowerCase() == c.name.toLowerCase());
        if (!exists) {
          await _customerBox.put(c.id, c);
          count++;
        }
      }
      return "Successfully imported $count customers!";
    }
    return "No customers found in Excel.";
  }
}