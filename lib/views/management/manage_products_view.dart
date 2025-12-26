import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/data_repository.dart';
import '../catalog/add_product_view.dart';
import 'edit_product_view.dart';

enum CatalogSort { nameAsc, nameDesc, priceLow, priceHigh }

class ManageProductsView extends StatefulWidget {
  const ManageProductsView({super.key});

  @override
  State<ManageProductsView> createState() => _ManageProductsViewState();
}

class _ManageProductsViewState extends State<ManageProductsView> {
  final DataRepository _repo = DataRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _ungroupedProducts = [];
  Map<String, Map<String, List<ProductModel>>> _masterGroups = {};
  
  List<ProductModel> _filteredUngrouped = [];
  Map<String, Map<String, List<ProductModel>>> _filteredGroups = {};
  
  String? _expandedGroup;
  CatalogSort _sortOption = CatalogSort.nameAsc;

  final Color _brandBlue = const Color(0xFF1A237E);
  final Color _bgGrey = const Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final products = _repo.getAllProducts();
    _sortProducts(products);

    List<ProductModel> ungrouped = [];
    Map<String, Map<String, List<ProductModel>>> groups = {};
    
    for (var p in products) {
      String gName = p.group.trim();
      String cName = p.category.trim(); 

      if (gName.isEmpty) { ungrouped.add(p); continue; }

      if (!groups.containsKey(gName)) groups[gName] = {};
      if (!groups[gName]!.containsKey(cName)) groups[gName]![cName] = [];
      groups[gName]![cName]!.add(p);
    }

    setState(() {
      _masterGroups = groups;
      _ungroupedProducts = ungrouped;
      _filteredGroups = groups;
      _filteredUngrouped = ungrouped;
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
      setState(() { _filteredGroups = _masterGroups; _filteredUngrouped = _ungroupedProducts; });
      return;
    }

    String lowerQuery = query.toLowerCase();
    List<ProductModel> tempUngrouped = _ungroupedProducts.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
    Map<String, Map<String, List<ProductModel>>> tempGroups = {};
    _masterGroups.forEach((groupName, categories) {
      if (groupName.toLowerCase().contains(lowerQuery)) {
        tempGroups[groupName] = categories;
      } else {
        Map<String, List<ProductModel>> tempCategories = {};
        categories.forEach((catName, items) {
          if (catName.isNotEmpty && catName.toLowerCase().contains(lowerQuery)) {
            tempCategories[catName] = items;
          } else {
            List<ProductModel> matchingItems = items.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
            if (matchingItems.isNotEmpty) tempCategories[catName] = matchingItems;
          }
        });
        if (tempCategories.isNotEmpty) tempGroups[groupName] = tempCategories;
      }
    });

    setState(() { _filteredGroups = tempGroups; _filteredUngrouped = tempUngrouped; });
  }

  void _editHeader(String oldName, bool isGroup, List<ProductModel> items) { TextEditingController ctrl = TextEditingController(text: oldName); showDialog(context: context, builder: (ctx) => AlertDialog(title: Text("Rename"), content: TextField(controller: ctrl), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () async {Navigator.pop(ctx); if(ctrl.text.isNotEmpty && ctrl.text != oldName) { if(isGroup) await _repo.renameGroup(oldName, ctrl.text); else await _repo.renameCategory(items.first.group, oldName, ctrl.text); _loadData(); }}, child: const Text("Save"))])); }
  void _deleteHeader(String name, bool isGroup, List<ProductModel> items) { showDialog(context: context, builder: (ctx) => AlertDialog(title: Text("Delete $name?"), content: const Text("Delete all items inside?"), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async {Navigator.pop(ctx); if(isGroup) await _repo.deleteGroup(name); else await _repo.deleteCategory(items.first.group, name); _loadData();}, child: const Text("Delete"))])); }
  void _addNewItem({String? group, String? category}) async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductView(initialGroup: group, initialCategory: category))); _loadData(); }
  void _showAddOptions() { showModalBottomSheet(context: context, backgroundColor: Colors.white, builder: (ctx) => Wrap(children: [ListTile(leading: const Icon(Icons.add_box, color: Colors.blue), title: const Text("Add Manual"), onTap: (){Navigator.pop(ctx); _addNewItem();}), ListTile(leading: const Icon(Icons.file_upload, color: Colors.green), title: const Text("Import Excel"), onTap: () async {Navigator.pop(ctx); await _repo.importProductData(); _loadData();})])); }
  Widget _buildSafeImage(String? path) { if (path == null || path.isEmpty) return const Icon(Icons.image, size: 40, color: Colors.grey); return Image.file(io.File(path), width: 40, height: 40, fit: BoxFit.cover, cacheWidth: 100, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey)); }

  @override
  Widget build(BuildContext context) {
    bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(title: const Text("Manage Products", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: _brandBlue, foregroundColor: Colors.white, elevation: 2, actions: [
          PopupMenuButton<CatalogSort>(icon: const Icon(Icons.sort), onSelected: (val) { setState(() => _sortOption = val); _applySort(); }, itemBuilder: (ctx) => [const PopupMenuItem(value: CatalogSort.nameAsc, child: Text("Name: A-Z")), const PopupMenuItem(value: CatalogSort.nameDesc, child: Text("Name: Z-A")), const PopupMenuItem(value: CatalogSort.priceLow, child: Text("Price: Low to High")), const PopupMenuItem(value: CatalogSort.priceHigh, child: Text("Price: High to Low"))])
        ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showAddOptions, backgroundColor: _brandBlue, icon: const Icon(Icons.add, color: Colors.white), label: const Text("Add", style: TextStyle(color: Colors.white))),
      body: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), color: Colors.white, child: TextField(controller: _searchController, decoration: InputDecoration(hintText: "Search...", prefixIcon: Icon(Icons.search, color: _brandBlue), suffixIcon: isSearching ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _runSearch(""); }) : null, filled: true, fillColor: const Color(0xFFE8EAF6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), onChanged: _runSearch)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                ..._filteredUngrouped.map((p) => Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)), child: _buildProductTile(p))),
                ...List.generate(_filteredGroups.length, (i) {
                  String groupName = _filteredGroups.keys.elementAt(i);
                  var cats = _filteredGroups[groupName]!;
                  var subCategories = cats.entries.where((e) => e.key.trim().isNotEmpty && e.key.toLowerCase() != "null").toList();
                  var directItems = cats.entries.where((e) => e.key.trim().isEmpty || e.key.toLowerCase() == "null").expand((e) => e.value).toList();

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    child: ExpansionTile(
                      key: Key(groupName + isSearching.toString() + (_expandedGroup == groupName).toString()), initiallyExpanded: isSearching || _expandedGroup == groupName, onExpansionChanged: (isOpen) { if (isOpen) setState(() => _expandedGroup = groupName); },
                      title: Row(children: [Expanded(child: Text(groupName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _brandBlue))), IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Item to Group", onPressed: () => _addNewItem(group: groupName)), IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.grey), onPressed: ()=>_editHeader(groupName, true, cats.values.expand((x)=>x).toList())), IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: ()=>_deleteHeader(groupName, true, cats.values.expand((x)=>x).toList()))]),
                      children: [
                        ...subCategories.map((cEntry) {
                          return ExpansionTile(
                            key: Key(cEntry.key + isSearching.toString()), initiallyExpanded: isSearching, 
                            title: Row(children: [Expanded(child: Text(cEntry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))), IconButton(icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green), tooltip: "Add Item here", onPressed: () => _addNewItem(group: groupName, category: cEntry.key)), IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: ()=>_editHeader(cEntry.key, false, cEntry.value)), IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.red), onPressed: ()=>_deleteHeader(cEntry.key, false, cEntry.value))]),
                            children: cEntry.value.map((p) => _buildProductTile(p)).toList(),
                          );
                        }),
                        ...directItems.map((p) => _buildProductTile(p)),
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

  Widget _buildProductTile(ProductModel p) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: _buildSafeImage(p.image)),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("₹${p.price.toStringAsFixed(0)} / ${p.uom}"),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductView(product: p))); _loadData(); }), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { await _repo.deleteProduct(p.id); _loadData(); })]),
      ),
    );
  }
}