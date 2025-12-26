import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/data_repository.dart';

enum CatalogSort { nameAsc, nameDesc, priceLow, priceHigh }

class ReadOnlyCatalogView extends StatefulWidget {
  const ReadOnlyCatalogView({super.key});

  @override
  State<ReadOnlyCatalogView> createState() => _ReadOnlyCatalogViewState();
}

class _ReadOnlyCatalogViewState extends State<ReadOnlyCatalogView> {
  final DataRepository _repo = DataRepository();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, Map<String, List<ProductModel>>> _masterGrouped = {};
  Map<String, Map<String, List<ProductModel>>> _filteredGrouped = {};
  
  String? _expandedGroup;
  CatalogSort _sortOption = CatalogSort.nameAsc;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final products = _repo.getAllProducts();
    _sortProducts(products);

    Map<String, Map<String, List<ProductModel>>> groups = {};

    for (var p in products) {
      String gName = p.group.trim();
      String cName = p.category.trim(); 
      if (gName.isEmpty) gName = "Other"; 

      if (!groups.containsKey(gName)) groups[gName] = {};
      if (!groups[gName]!.containsKey(cName)) groups[gName]![cName] = [];
      groups[gName]![cName]!.add(p);
    }
    setState(() {
      _masterGrouped = groups;
      _filteredGrouped = groups;
    });
  }

  void _sortProducts(List<ProductModel> list) {
    switch (_sortOption) {
      case CatalogSort.nameAsc: list.sort((a, b) => a.name.compareTo(b.name)); break;
      case CatalogSort.nameDesc: list.sort((a, b) => b.name.compareTo(a.name)); break;
      case CatalogSort.priceLow: list.sort((a, b) => a.price.compareTo(b.price)); break;
      case CatalogSort.priceHigh: list.sort((a, b) => b.price.compareTo(a.price)); break;
    }
  }

  void _applySort() { _loadData(); }

  void _runSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredGrouped = _masterGrouped);
      return;
    }
    String lowerQuery = query.toLowerCase();
    Map<String, Map<String, List<ProductModel>>> tempGrouped = {};
    _masterGrouped.forEach((groupName, categories) {
      if (groupName.toLowerCase().contains(lowerQuery)) {
        tempGrouped[groupName] = categories;
      } else {
        Map<String, List<ProductModel>> tempCats = {};
        categories.forEach((catName, items) {
          if (catName.isNotEmpty && catName.toLowerCase().contains(lowerQuery)) {
            tempCats[catName] = items;
          } else {
            List<ProductModel> matching = items.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
            if (matching.isNotEmpty) tempCats[catName] = matching;
          }
        });
        if (tempCats.isNotEmpty) tempGrouped[groupName] = tempCats;
      }
    });
    setState(() => _filteredGrouped = tempGrouped);
  }

  // --- PDF GENERATION ---
  Future<void> _generateGroupPdf(String groupName, Map<String, List<ProductModel>> categories, bool withPrices) async {
    final pdf = pw.Document();
    final fontBold = pw.Font.helveticaBold();
    final fontRegular = pw.Font.helvetica();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];
          widgets.add(pw.Header(level: 0, child: pw.Text(groupName, style: pw.TextStyle(font: fontBold, fontSize: 20))));
          widgets.add(pw.SizedBox(height: 10));

          categories.forEach((catName, products) {
            widgets.add(pw.Container(width: double.infinity, color: PdfColors.grey200, padding: const pw.EdgeInsets.all(5), child: pw.Text(catName, style: pw.TextStyle(font: fontBold, fontSize: 14))));
            
            widgets.add(
              pw.TableHelper.fromTextArray(
                border: null,
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
                cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
                // REMOVED VARIANT COLUMN
                headers: withPrices ? ['Item Name', 'Unit', 'Price'] : ['Item Name', 'Unit'],
                data: products.map((p) {
                  return withPrices 
                    ? [p.name, p.uom, "Rs. ${p.price.toStringAsFixed(0)}"]
                    : [p.name, p.uom];
                }).toList(),
                columnWidths: withPrices 
                  ? {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)}
                  : {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1)},
              )
            );
            widgets.add(pw.SizedBox(height: 15));
          });
          return widgets;
        }
      )
    );

    final output = await getTemporaryDirectory();
    final file = io.File("${output.path}/$groupName.pdf");
    await file.writeAsBytes(await pdf.save());
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      await Share.shareXFiles([XFile(file.path)], text: 'Price List: $groupName');
    }
  }

  void _showPdfOptions(String groupName, Map<String, List<ProductModel>> categories) {
    showModalBottomSheet(
      context: context, 
      builder: (ctx) => Wrap(
        children: [
          ListTile(leading: const Icon(Icons.attach_money, color: Colors.green), title: const Text("Generate With Prices"), onTap: () { Navigator.pop(ctx); _generateGroupPdf(groupName, categories, true); }),
          ListTile(leading: const Icon(Icons.money_off, color: Colors.red), title: const Text("Generate Without Prices"), onTap: () { Navigator.pop(ctx); _generateGroupPdf(groupName, categories, false); })
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Product Price List", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), actions: [
          PopupMenuButton<CatalogSort>(icon: const Icon(Icons.sort), onSelected: (val) { setState(() => _sortOption = val); _applySort(); }, itemBuilder: (ctx) => [const PopupMenuItem(value: CatalogSort.nameAsc, child: Text("Name: A-Z")), const PopupMenuItem(value: CatalogSort.nameDesc, child: Text("Name: Z-A")), const PopupMenuItem(value: CatalogSort.priceLow, child: Text("Price: Low to High")), const PopupMenuItem(value: CatalogSort.priceHigh, child: Text("Price: High to Low"))])
        ]),
      body: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), color: Colors.white, child: TextField(controller: _searchController, decoration: InputDecoration(hintText: "Search...", prefixIcon: const Icon(Icons.search, color: Colors.grey), suffixIcon: isSearching ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _runSearch(""); }) : null, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)), onChanged: _runSearch)),
          Expanded(
            child: ListView(
              children: [
                ..._filteredGrouped.entries.map((gEntry) {
                  String groupName = gEntry.key;
                  var cats = gEntry.value;
                  var subCategories = cats.entries.where((e) => e.key.trim().isNotEmpty && e.key.toLowerCase() != "null").toList();
                  var directItems = cats.entries.where((e) => e.key.trim().isEmpty || e.key.toLowerCase() == "null").expand((e)=>e.value).toList();

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ExpansionTile(
                      key: Key(groupName + (_expandedGroup == groupName).toString()),
                      initiallyExpanded: isSearching || _expandedGroup == groupName,
                      onExpansionChanged: (isOpen) { if (isOpen) setState(() => _expandedGroup = groupName); },
                      backgroundColor: Colors.white, collapsedBackgroundColor: Colors.white,
                      title: Row(children: [Expanded(child: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1565C0)))), IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), onPressed: () => _showPdfOptions(groupName, cats))]),
                      children: [
                        ...subCategories.map((cEntry) {
                          return ExpansionTile(
                            title: Text(cEntry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            children: cEntry.value.map((product) => _buildReadOnlyRow(product)).toList(),
                          );
                        }),
                        ...directItems.map((product) => _buildReadOnlyRow(product)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(ProductModel product) {
    bool hasSecondary = product.secondaryUom != null && product.price2 != null;
    Widget imageWidget = const Icon(Icons.image, color: Colors.grey, size: 35);
    if (product.image.isNotEmpty && io.File(product.image).existsSync()) { imageWidget = Image.file(io.File(product.image), fit: BoxFit.cover, errorBuilder: (c,o,s)=>const Icon(Icons.broken_image)); }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100)), color: Colors.white),
      child: Row(children: [
        Container(width: 45, height: 45, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)), child: ClipRRect(borderRadius: BorderRadius.circular(6), child: imageWidget)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          // REMOVED VARIANT TEXT HERE
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("₹${product.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1565C0))), Text("per ${product.uom}", style: const TextStyle(fontSize: 11, color: Colors.grey)), if (hasSecondary) ...[const SizedBox(height: 4), Text("₹${product.price2!.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)), Text("per ${product.secondaryUom}", style: const TextStyle(fontSize: 11, color: Colors.grey))]])
      ]),
    );
  }
}