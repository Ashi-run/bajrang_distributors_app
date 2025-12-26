import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/repositories/data_repository.dart';
import '../../viewmodels/cart_provider.dart';
import '../dashboard/dashboard_view.dart';

class CartView extends ConsumerStatefulWidget {
  final CustomerModel? preSelectedCustomer;
  const CartView({super.key, this.preSelectedCustomer});

  @override
  ConsumerState<CartView> createState() => _CartViewState();
}

class _CartViewState extends ConsumerState<CartView> {
  final DataRepository _repo = DataRepository();
  CustomerModel? _selectedCustomer;
  final TextEditingController _remarkCtrl = TextEditingController();
  List<CustomerModel> _allCustomers = [];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;
    _loadCustomers();
  }

  void _loadCustomers() {
    setState(() {
      _allCustomers = _repo.getAllCustomers();
    });
  }

  String _generateOrderId() {
    final box = Hive.box<OrderModel>('orders_v2');
    int maxId = 0; 
    for (var order in box.values) {
      int? currentId = int.tryParse(order.id);
      if (currentId != null && currentId < 900000) { 
        if (currentId > maxId) maxId = currentId;
      }
    }
    return (maxId + 1).toString();
  }

  void _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Select a Customer!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
      );
      return;
    }
    
    final String permanentId = _generateOrderId();

    final order = OrderModel(
      id: permanentId, 
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      date: DateTime.now(),
      totalAmount: ref.read(cartProvider.notifier).totalAmount,
      discount: 0,
      items: cart,
      isApproved: false,
    );

    await Hive.box<OrderModel>('orders_v2').add(order);
    ref.read(cartProvider.notifier).clearCart();

    if (mounted) {
      String displayId = permanentId.padLeft(4, '0');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order #$displayId Placed Successfully!")));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardView()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Review Order", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // CUSTOMER SELECT
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Customer:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                if (_selectedCustomer != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(_selectedCustomer!.phone),
                    trailing: TextButton(
                      onPressed: () => setState(() => _selectedCustomer = null),
                      child: const Text("CHANGE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Autocomplete<CustomerModel>(
                      optionsBuilder: (val) => val.text.isEmpty ? [] : _allCustomers.where((c) => c.name.toLowerCase().contains(val.text.toLowerCase())),
                      displayStringForOption: (c) => c.name,
                      onSelected: (c) => setState(() => _selectedCustomer = c),
                      fieldViewBuilder: (ctx, ctrl, node, submit) => TextField(
                        controller: ctrl, focusNode: node,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search & Select Customer...",
                          icon: Icon(Icons.search, color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: cartItems.length,
              itemBuilder: (ctx, i) {
                final item = cartItems[i];
                
                // CALCULATE STANDARD PRICE TO CHECK MODIFICATION
                double standardRate = item.product.price;
                if (item.uom == item.product.secondaryUom) {
                   standardRate = (item.product.price2 != null && item.product.price2! > 0)
                      ? item.product.price2!
                      : item.product.price * (item.product.conversionFactor ?? 1);
                }
                bool isRateModified = (item.sellPrice - standardRate).abs() > 0.1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            Text("₹${item.total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildQtyControl(item),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildUomDropdown(item),
                            ),
                            const SizedBox(width: 8),
                            
                            // RATE INPUT WITH MODIFIED INDICATOR
                            Expanded(
                              flex: 3, 
                              child: Column(
                                children: [
                                  _buildInputBox(
                                    label: "Rate", 
                                    value: item.sellPrice.toStringAsFixed(0), 
                                    onChanged: (val) => ref.read(cartProvider.notifier).updatePrice(item.product, double.tryParse(val) ?? 0)
                                  ),
                                  if (isRateModified)
                                    Text(
                                      "List: ${standardRate.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Colors.red, 
                                        fontSize: 10, 
                                        decoration: TextDecoration.lineThrough,
                                        fontWeight: FontWeight.bold
                                      ),
                                    )
                                ],
                              )
                            ),
                            
                            const SizedBox(width: 5),
                            Expanded(flex: 2, child: _buildInputBox(label: "Scheme", value: item.scheme, isText: true, onChanged: (val) => ref.read(cartProvider.notifier).updateScheme(item.product, val))),
                            const SizedBox(width: 5),
                            Expanded(flex: 2, child: _buildInputBox(label: "Disc", value: item.discount > 0 ? item.discount.toString() : "", onChanged: (val) => ref.read(cartProvider.notifier).updateDiscount(item.product, double.tryParse(val) ?? 0))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // BOTTOM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))]),
            child: Column(
              children: [
                TextField(controller: _remarkCtrl, decoration: const InputDecoration(labelText: "Order Remark", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8))),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Payable:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("₹ ${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 22))]),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _placeOrder, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F00), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("PLACE ORDER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildUomDropdown(CartItem item) {
    if (item.product.secondaryUom == null || item.product.secondaryUom!.isEmpty) {
      return Padding(padding: const EdgeInsets.only(bottom: 8.0, right: 5), child: Text(item.uom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)));
    }
    return Column(children: [const Text(" Unit", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Container(height: 35, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: item.uom, isDense: true, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13), items: [DropdownMenuItem(value: item.product.uom, child: Text(item.product.uom)), DropdownMenuItem(value: item.product.secondaryUom!, child: Text(item.product.secondaryUom!))], onChanged: (val) { if (val != null && val != item.uom) { double newPrice = (val == item.product.secondaryUom) ? (item.product.price2 ?? item.product.price * (item.product.conversionFactor ?? 1)) : item.product.price; ref.read(cartProvider.notifier).updateUomAndPrice(item.product, val, newPrice); }})))]);
  }

  Widget _buildQtyControl(CartItem item) {
    final TextEditingController qtyCtrl = TextEditingController(text: "${item.quantity}");
    qtyCtrl.selection = TextSelection.fromPosition(TextPosition(offset: qtyCtrl.text.length));
    return Column(children: [const Text(" Qty", style: TextStyle(fontSize: 11, color: Colors.transparent)), Row(children: [InkWell(onTap: () => ref.read(cartProvider.notifier).decreaseItem(item.product), child: const CircleAvatar(radius: 14, backgroundColor: Colors.red, child: Icon(Icons.remove, size: 16, color: Colors.white))), const SizedBox(width: 5), SizedBox(width: 35, height: 35, child: TextFormField(key: ValueKey(item.quantity), controller: qtyCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), decoration: const InputDecoration(contentPadding: EdgeInsets.zero, border: UnderlineInputBorder()), onChanged: (val) { int newQty = int.tryParse(val) ?? 0; if (newQty > 0) ref.read(cartProvider.notifier).updateQuantity(item.product, newQty); })), const SizedBox(width: 5), InkWell(onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.product, item.quantity + 1), child: const CircleAvatar(radius: 14, backgroundColor: Colors.green, child: Icon(Icons.add, size: 16, color: Colors.white)))])]);
  }

  Widget _buildInputBox({required String label, required String value, required Function(String) onChanged, bool isText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(" $label", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), 
        SizedBox(
          height: 35, 
          child: TextFormField(
            key: ValueKey(value), // <--- THIS FIXED IT
            initialValue: value, 
            keyboardType: isText ? TextInputType.text : TextInputType.number, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), 
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)), 
              isDense: true
            ), 
            onChanged: onChanged
          )
        )
      ]
    );
  }
}