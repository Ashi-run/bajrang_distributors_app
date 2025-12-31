import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/data_repository.dart';
import '../../viewmodels/cart_provider.dart';
import '../cart/cart_view.dart';
import '../cart/add_customer_view.dart';

enum CatalogSort { nameAsc, nameDesc, priceLow, priceHigh }

class BajrangCatalog extends ConsumerStatefulWidget {
  const BajrangCatalog({super.key});

  @override
  ConsumerState<BajrangCatalog> createState() => _BajrangCatalogState();
}

class _BajrangCatalogState extends ConsumerState<BajrangCatalog> {
  final DataRepository _repo = DataRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _allProducts = [];
  List<CustomerModel> _allCustomers = [];
  CustomerModel? _selectedCustomer;

  List<ProductModel> _ungroupedProducts = [];
  Map<String, Map<String, List<ProductModel>>> _masterGroups = {};
  
  List<ProductModel> _filteredUngrouped = [];
  Map<String, Map<String, List<ProductModel>>> _filteredGroups = {};
  
  String? _expandedGroup;
  CatalogSort _sortOption = CatalogSort.nameAsc;

  final Map<String, String> _activeUom = {};
  final Color _brandBlue = const Color(0xFF1A237E);
  final Color _brandOrange = const Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final products = _repo.getAllProducts();
    final customers = _repo.getAllCustomers();
    _sortProducts(products);

    List<ProductModel> ungrouped = [];
    Map<String, Map<String, List<ProductModel>>> groups = {};

    for (var p in products) {
      String gName = p.group.trim();
      String cName = p.category.trim();
      _activeUom[p.id] = p.uom;

      if (gName.isEmpty) { ungrouped.add(p); continue; }

      if (!groups.containsKey(gName)) groups[gName] = {};
      if (!groups[gName]!.containsKey(cName)) groups[gName]![cName] = [];
      groups[gName]![cName]!.add(p);
    }

    setState(() {
      _allProducts = products;
      _allCustomers = customers;
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

  void _navigateToAddCustomer(String initialName) async {
    final newCustomer = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddCustomerView(initialName: initialName)));
    _loadData(); 
    if (newCustomer != null && newCustomer is CustomerModel) {
      setState(() => _selectedCustomer = newCustomer);
    }
  }

  void _runSearch(String query) {
    if (query.isEmpty) {
      setState(() { _filteredGroups = _masterGroups; _filteredUngrouped = _ungroupedProducts; });
      return;
    }
    String lowerQuery = query.toLowerCase();
    List<ProductModel> tempUngrouped = _ungroupedProducts.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
    Map<String, Map<String, List<ProductModel>>> tempGroups = {};
    _masterGroups.forEach((groupName, categories) {
      bool groupMatch = groupName.toLowerCase().contains(lowerQuery);
      if (groupMatch) {
        tempGroups[groupName] = categories;
      } else {
        Map<String, List<ProductModel>> tempCategories = {};
        categories.forEach((catName, products) {
          bool catMatch = catName.isNotEmpty && catName.toLowerCase().contains(lowerQuery);
          if (catMatch) {
            tempCategories[catName] = products;
          } else {
            List<ProductModel> matching = products.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
            if (matching.isNotEmpty) tempCategories[catName] = matching;
          }
        });
        if (tempCategories.isNotEmpty) tempGroups[groupName] = tempCategories;
      }
    });
    setState(() { _filteredGroups = tempGroups; _filteredUngrouped = tempUngrouped; });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalPayable = ref.watch(cartProvider.notifier).totalAmount;
    bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Place Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 2,
        actions: [
          PopupMenuButton<CatalogSort>(
            icon: const Icon(Icons.sort),
            onSelected: (val) { setState(() => _sortOption = val); _applySort(); },
            itemBuilder: (ctx) => [const PopupMenuItem(value: CatalogSort.nameAsc, child: Text("Name: A-Z")), const PopupMenuItem(value: CatalogSort.nameDesc, child: Text("Name: Z-A")), const PopupMenuItem(value: CatalogSort.priceLow, child: Text("Price: Low to High")), const PopupMenuItem(value: CatalogSort.priceHigh, child: Text("Price: High to Low"))],
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12), color: Colors.white,
            child: _selectedCustomer != null 
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                child: Row(children: [const CircleAvatar(radius: 18, backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), if(_selectedCustomer!.address.isNotEmpty) Text(_selectedCustomer!.address, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)])), TextButton.icon(onPressed: () => setState(() { _selectedCustomer = null; }), icon: const Icon(Icons.close, size: 16), label: const Text("CHANGE"), style: TextButton.styleFrom(foregroundColor: Colors.red))]),
              )
            : Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(8), border: Border.all(color: _brandBlue.withOpacity(0.2))),
              child: Autocomplete<CustomerModel>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<CustomerModel>.empty();
                  final matches = _allCustomers.where((c) => c.name.toLowerCase().contains(textEditingValue.text.toLowerCase())).toList();
                  matches.add(CustomerModel(id: 'INLINE_ADD', name: '➕ Add new: "${textEditingValue.text}"', phone: '', address: ''));
                  return matches;
                },
                displayStringForOption: (c) => c.name,
                onSelected: (c) {
                  if (c.id == 'INLINE_ADD') {
                    String newName = c.name.replaceAll('➕ Add new: "', '').replaceAll('"', '');
                    _navigateToAddCustomer(newName);
                  } else {
                    setState(() => _selectedCustomer = c);
                  }
                },
                fieldViewBuilder: (ctx, ctrl, node, submit) => TextField(controller: ctrl, focusNode: node, style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold), decoration: InputDecoration(icon: Icon(Icons.person_pin_circle, color: _brandBlue), hintText: "Search Customer...", border: InputBorder.none)),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: TextField(controller: _searchController, decoration: InputDecoration(hintText: "Search Groups, Items...", prefixIcon: const Icon(Icons.search, color: Colors.grey), suffixIcon: isSearching ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _runSearch(""); }) : null, filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.zero, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _brandBlue, width: 1.5))), onChanged: _runSearch)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                ..._filteredUngrouped.map((p) => Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)), child: _buildProductCard(p))),
                ...List.generate(_filteredGroups.length, (i) {
                  String groupName = _filteredGroups.keys.elementAt(i);
                  var cats = _filteredGroups[groupName]!;
                  var subCategories = cats.entries.where((e) => e.key.trim().isNotEmpty && e.key.toLowerCase() != "null").toList();
                  var directItems = cats.entries.where((e) => e.key.trim().isEmpty || e.key.toLowerCase() == "null").expand((e) => e.value).toList();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                    child: ExpansionTile(
                      key: Key(groupName + isSearching.toString() + (_expandedGroup == groupName).toString()),
                      initiallyExpanded: isSearching || _expandedGroup == groupName,
                      onExpansionChanged: (isOpen) { if (isOpen) setState(() => _expandedGroup = groupName); },
                      backgroundColor: Colors.white, collapsedBackgroundColor: Colors.white,
                      title: Text(groupName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _brandBlue)),
                      children: [
                        ...subCategories.map((cEntry) {
                          return ExpansionTile(
                            key: Key(cEntry.key + isSearching.toString()), initiallyExpanded: isSearching, 
                            title: Text(cEntry.key, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.blueGrey[800])),
                            children: cEntry.value.map((product) => _buildProductCard(product)).toList(),
                          );
                        }),
                        ...directItems.map((product) => _buildProductCard(product)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (cartItems.isNotEmpty) 
            Container(
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))]), 
              child: SafeArea( 
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [const Text("TOTAL PAYABLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)), Text("₹ ${totalPayable.toStringAsFixed(2)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _brandBlue))]), 
                      const Spacer(), 
                      ElevatedButton.icon(icon: const Icon(Icons.check_circle_outline, size: 20), label: const Text("REVIEW ORDER", style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: _brandOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartView(preSelectedCustomer: _selectedCustomer))))
                    ]
                  ),
                )
              )
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final cartItems = ref.watch(cartProvider);
    final cartItem = cartItems.firstWhere((item) => item.product.id == product.id, orElse: () => CartItem(product: product, quantity: 0, sellPrice: 0.0, uom: product.uom, originalQty: 0));
    
    String currentUom = cartItem.quantity > 0 ? cartItem.uom : (_activeUom[product.id] ?? product.uom);
    
    // --- EFFECTIVE PRICE (UNIT STRICT) ---
    // Pass currentUom to get the price SPECIFIC to that unit
    double effectivePrice = _repo.getEffectivePrice(product, _selectedCustomer?.name, currentUom);
    
    double displayPrice = 0.0;
    
    if (cartItem.quantity > 0) {
      displayPrice = cartItem.sellPrice;
    } else {
      displayPrice = effectivePrice;
    }

    bool inCart = cartItem.quantity > 0;
    Widget imageWidget = const Icon(Icons.image, color: Colors.grey, size: 30);
    if (product.image.isNotEmpty && io.File(product.image).existsSync()) { imageWidget = Image.file(io.File(product.image), fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.broken_image)); }

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100)), color: inCart ? _brandBlue.withOpacity(0.03) : Colors.white),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)), child: ClipRRect(borderRadius: BorderRadius.circular(6), child: imageWidget)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 6), Row(children: [Container(height: 26, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)), child: DropdownButton<String>(value: currentUom, isDense: true, underline: Container(), iconSize: 16, style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold, fontSize: 12), items: [DropdownMenuItem(value: product.uom, child: Text(product.uom)), if (product.secondaryUom != null) DropdownMenuItem(value: product.secondaryUom!, child: Text(product.secondaryUom!))], onChanged: (val) { if (val != null) { 
        setState(() => _activeUom[product.id] = val); 
        // Force rebuild or specific logic to fetch new effective price happens on next build
        if (inCart) { 
          // If in cart, we might want to keep cart price OR recalc. Usually, changing UOM in cart updates price to default/history.
          double newBasePrice = _repo.getEffectivePrice(product, _selectedCustomer?.name, val);
          ref.read(cartProvider.notifier).updateUomAndPrice(product, val, newBasePrice); 
        } 
      } })), const SizedBox(width: 8), Text("₹ ", style: TextStyle(fontWeight: FontWeight.bold, color: _brandBlue)), 
            
            // RATE INPUT
            _RateInput(
              initialRate: displayPrice, 
              onChanged: (newRate) { 
                if (newRate > 0) { 
                  if (inCart) { 
                    ref.read(cartProvider.notifier).updatePrice(product, newRate); 
                  } else { 
                    ref.read(cartProvider.notifier).addItem(product, _selectedCustomer); 
                    ref.read(cartProvider.notifier).updatePrice(product, newRate); 
                    if (currentUom != product.uom) ref.read(cartProvider.notifier).updateUom(product, currentUom); 
                  } 
                } 
              }
            ),
            
            ]), if (currentUom == product.secondaryUom && product.secondaryUom != null && product.conversionFactor != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text("ⓘ 1 ${product.secondaryUom} = ${product.conversionFactor} ${product.uom}", style: TextStyle(fontSize: 11, color: _brandOrange, fontWeight: FontWeight.bold)))]))]), const SizedBox(height: 10), Row(children: [Container(height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: inCart ? _brandBlue : Colors.grey.shade300)), child: Row(children: [IconButton(icon: Icon(Icons.remove, size: 16, color: inCart ? _brandBlue : Colors.grey), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36), onPressed: () => ref.read(cartProvider.notifier).decreaseItem(product)), Container(width: 1, height: 20, color: Colors.grey.shade200), 
            
            _QuantityInput(quantity: cartItem.quantity, onChanged: (newQty) { 
              if (newQty > 0) { 
                if (cartItem.quantity == 0) { 
                  // Add Item Logic using current UI price
                  ref.read(cartProvider.notifier).addItem(product, _selectedCustomer); 
                  ref.read(cartProvider.notifier).updatePrice(product, displayPrice); 
                  if (currentUom != product.uom) ref.read(cartProvider.notifier).updateUom(product, currentUom); 
                  if (newQty > 1) ref.read(cartProvider.notifier).updateQuantity(product, newQty); 
                } else { 
                  ref.read(cartProvider.notifier).updateQuantity(product, newQty); 
                } 
              } else if (newQty == 0 && cartItem.quantity > 0) { 
                ref.read(cartProvider.notifier).updateQuantity(product, 0); 
              } 
            }), 
            
            Container(width: 1, height: 20, color: Colors.grey.shade200), 
            IconButton(icon: const Icon(Icons.add, size: 16, color: Colors.green), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36), onPressed: () { 
              if (cartItem.quantity > 0) { 
                ref.read(cartProvider.notifier).updateQuantity(product, cartItem.quantity + 1); 
              } else { 
                // Add Item Logic using current UI price
                ref.read(cartProvider.notifier).addItem(product, _selectedCustomer); 
                ref.read(cartProvider.notifier).updatePrice(product, displayPrice); 
                if (currentUom != product.uom) ref.read(cartProvider.notifier).updateUom(product, currentUom);
              } 
            })])), const SizedBox(width: 8), Expanded(child: TextFormField(initialValue: cartItem.scheme, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "Scheme", isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300))), onChanged: (v) => ref.read(cartProvider.notifier).updateScheme(product, v))), const SizedBox(width: 5), Expanded(child: TextFormField(initialValue: cartItem.discount > 0 ? "${cartItem.discount}" : "", keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "Disc", isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300))), onChanged: (v) => ref.read(cartProvider.notifier).updateDiscount(product, double.tryParse(v) ?? 0)))])]),
    );
  }
}

class _QuantityInput extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  const _QuantityInput({super.key, required this.quantity, required this.onChanged});
  @override
  State<_QuantityInput> createState() => _QuantityInputState();
}
class _QuantityInputState extends State<_QuantityInput> {
  late TextEditingController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.quantity == 0 ? "" : "${widget.quantity}"); }
  @override
  void didUpdateWidget(_QuantityInput oldWidget) { super.didUpdateWidget(oldWidget); if (widget.quantity != oldWidget.quantity) { int currentInput = int.tryParse(_ctrl.text) ?? 0; if (currentInput != widget.quantity) { _ctrl.text = widget.quantity == 0 ? "" : "${widget.quantity}"; } } }
  @override
  Widget build(BuildContext context) { return SizedBox(width: 40, child: TextFormField(controller: _ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "0", hintStyle: TextStyle(color: Colors.grey)), onChanged: (val) => widget.onChanged(int.tryParse(val) ?? 0))); }
}

class _RateInput extends StatefulWidget {
  final double initialRate;
  final ValueChanged<double> onChanged;
  const _RateInput({required this.initialRate, required this.onChanged});
  @override
  State<_RateInput> createState() => _RateInputState();
}
class _RateInputState extends State<_RateInput> {
  late TextEditingController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.initialRate.toStringAsFixed(0)); }
  @override
  void didUpdateWidget(_RateInput oldWidget) { 
    super.didUpdateWidget(oldWidget); 
    if (widget.initialRate != oldWidget.initialRate) { 
      double currentInput = double.tryParse(_ctrl.text) ?? 0.0; 
      if (currentInput != widget.initialRate) { 
        _ctrl.text = widget.initialRate.toStringAsFixed(0); 
      } 
    } 
  }
  @override
  Widget build(BuildContext context) { return SizedBox(width: 60, height: 30, child: TextFormField(controller: _ctrl, keyboardType: TextInputType.number, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(bottom: 4), border: UnderlineInputBorder()), onChanged: (val) => widget.onChanged(double.tryParse(val) ?? 0.0))); }
}