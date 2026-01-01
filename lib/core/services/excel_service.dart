import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';

class ExcelService {
  
  // --- 1. PRODUCT IMPORT ---
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

            // Extract Conversion Factor (e.g. 30)
            double extractFactor(int index) {
              if (index >= row.length || row[index] == null) return 1.0;
              String val = row[index]!.value.toString();
              RegExp regExp = RegExp(r'[0-9]+(\.[0-9]+)?');
              Match? match = regExp.firstMatch(val);
              return match != null ? (double.tryParse(match.group(0)!) ?? 1.0) : 1.0;
            }

            // --- SMART PRICE IMPORT ---
            double basePrice = safeDouble(4); // Col 4: Base Price (Jar)
            double factor = extractFactor(7); // Col 7: Factor
            double secPrice = safeDouble(8);  // Col 8: Secondary Price (Ctn) -> NEW!

            // 1. If Ctn Price (4400) is present but Jar Price is 0, calculate Jar
            if (basePrice == 0 && secPrice > 0 && factor > 0) {
              basePrice = secPrice / factor; // 4400 / 30 = 146.6
            }

            // 2. If Jar Price (150) is present but Ctn Price is 0, calculate Ctn
            if (secPrice == 0 && basePrice > 0 && factor > 0) {
              secPrice = basePrice * factor; // 150 * 30 = 4500
            }

            products.add(ProductModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              group: safeVal(0),      
              category: safeVal(1),   
              name: safeVal(2),       
              uom: safeVal(3).isEmpty ? "Pkt" : safeVal(3), 
              price: basePrice,       // Saved as calculated or explicit
              image: safeVal(5),      
              secondaryUom: safeVal(6), 
              conversionFactor: factor,
              price2: secPrice,       // Saved explicitly
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

  // --- 2. CUSTOMER IMPORT (Unchanged) ---
  Future<List<CustomerModel>> pickAndParseCustomers() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        List<CustomerModel> customers = [];
        final sheet = excel.tables[excel.tables.keys.first];

        if (sheet != null) {
          for (var i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            if (row.isEmpty || row[0] == null) continue;
            String safeVal(int index) {
              if (index >= row.length || row[index] == null) return "";
              return row[index]!.value.toString().trim();
            }
            String name = safeVal(0);
            if (name.isEmpty) continue;
            customers.add(CustomerModel(
              id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
              name: name, phone: safeVal(1), address: safeVal(2),
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