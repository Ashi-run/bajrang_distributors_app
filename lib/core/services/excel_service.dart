import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart'; // Import Customer Model

class ExcelService {
  
  // --- 1. PRODUCT IMPORT (Existing) ---
  Future<List<ProductModel>> pickAndParseExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        List<ProductModel> products = [];
        final sheet = excel.tables[excel.tables.keys.first];

        if (sheet != null) {
          for (var i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            if (row.isEmpty || row[0] == null) continue;

            String safeVal(int index) {
              if (index >= row.length || row[index] == null) return "";
              return row[index]!.value.toString().trim();
            }

            double safeDouble(int index) {
              if (index >= row.length || row[index] == null) return 0.0;
              String clean = row[index]!.value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
              return double.tryParse(clean) ?? 0.0;
            }

            int extractFactor(int index) {
              if (index >= row.length || row[index] == null) return 1;
              String val = row[index]!.value.toString();
              RegExp regExp = RegExp(r'\d+');
              Match? match = regExp.firstMatch(val);
              return match != null ? (int.tryParse(match.group(0)!) ?? 1) : 1;
            }

            products.add(ProductModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              group: safeVal(0),      
              category: safeVal(1),   
              name: safeVal(2),       
              uom: safeVal(3).isEmpty ? "Pkt" : safeVal(3), 
              price: safeDouble(4),   
              image: safeVal(5),      
              secondaryUom: safeVal(6), 
              conversionFactor: extractFactor(7), 
              price2: 0.0, 
            ));
          }
        }
        return products;
      }
    } catch (e) {
      print("Product Import Error: $e");
    }
    return [];
  }

  // --- 2. CUSTOMER IMPORT (NEW) ---
  Future<List<CustomerModel>> pickAndParseCustomers() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        List<CustomerModel> customers = [];
        // Get first sheet
        final sheet = excel.tables[excel.tables.keys.first];

        if (sheet != null) {
          // Skip Header (Row 0), Start from Row 1
          for (var i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            
            // Safety check
            if (row.isEmpty || row[0] == null) continue;

            String safeVal(int index) {
              if (index >= row.length || row[index] == null) return "";
              return row[index]!.value.toString().trim();
            }

            // MAPPING: 
            // Col A (0): Name
            // Col B (1): Phone
            // Col C (2): Address
            
            String name = safeVal(0);
            if (name.isEmpty) continue; // Skip if name is empty

            customers.add(CustomerModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name,
              phone: safeVal(1),
              address: safeVal(2),
            ));
          }
        }
        return customers;
      }
    } catch (e) {
      print("Customer Import Error: $e");
    }
    return [];
  }
}