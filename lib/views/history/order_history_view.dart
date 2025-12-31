import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart'; 
import '../../core/services/pdf_service.dart';

enum OrderSort { dateNewest, dateOldest, amountHigh, amountLow }

class OrderHistoryView extends StatefulWidget {
  final int initialIndex; 
  const OrderHistoryView({super.key, this.initialIndex = 0});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  OrderSort _sortOption = OrderSort.dateNewest; 

  void _deleteOrder(BuildContext context, Box<OrderModel> box, dynamic key) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Order?"), 
        content: const Text("This cannot be undone."), 
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")), 
          TextButton(onPressed: (){ 
            box.delete(key); 
            Navigator.pop(ctx); 
          }, child: const Text("Delete", style: TextStyle(color: Colors.red)))
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Order History", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<OrderSort>(
              icon: const Icon(Icons.sort),
              onSelected: (val) => setState(() => _sortOption = val),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: OrderSort.dateNewest, child: Text("Date: Newest First")),
                const PopupMenuItem(value: OrderSort.dateOldest, child: Text("Date: Oldest First")),
                const PopupMenuItem(value: OrderSort.amountHigh, child: Text("Amount: High to Low")),
                const PopupMenuItem(value: OrderSort.amountLow, child: Text("Amount: Low to High")),
              ],
            )
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Orders"),      
              Tab(text: "Pending"),     
              Tab(text: "Approved"),    
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PendingOrdersTab(onDelete: _deleteOrder, sort: _sortOption),
            const _ItemWisePendingTab(), 
            _ApprovedOrdersTab(onDelete: _deleteOrder, sort: _sortOption),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: ORDERS (ACTIONABLE)
// ==========================================
class _PendingOrdersTab extends StatefulWidget {
  final Function(BuildContext, Box<OrderModel>, dynamic) onDelete;
  final OrderSort sort;
  const _PendingOrdersTab({required this.onDelete, required this.sort});

  @override
  State<_PendingOrdersTab> createState() => _PendingOrdersTabState();
}

class _PendingOrdersTabState extends State<_PendingOrdersTab> {
  String? _expandedOrderId;

  String _getAddress(String customerName) {
    try {
      final custBox = Hive.box<CustomerModel>('customers_v2');
      final customer = custBox.values.firstWhere(
        (c) => c.name.toLowerCase() == customerName.toLowerCase(),
        orElse: () => CustomerModel(id: '', name: '', phone: '', address: ''),
      );
      return customer.address;
    } catch (e) {
      return "";
    }
  }

  List<OrderModel> _sortOrders(List<OrderModel> list) {
    switch (widget.sort) {
      case OrderSort.dateNewest: list.sort((a, b) => b.date.compareTo(a.date)); break;
      case OrderSort.dateOldest: list.sort((a, b) => a.date.compareTo(b.date)); break;
      case OrderSort.amountHigh: list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount)); break;
      case OrderSort.amountLow: list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount)); break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<OrderModel>('orders_v2').listenable(),
      builder: (context, Box<OrderModel> box, _) {
        var orders = box.values.where((o) => !o.isApproved).toList();
        orders = _sortOrders(orders);

        if (orders.isEmpty) return const Center(child: Text("No Pending Orders", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final key = box.keys.firstWhere((k) => box.get(k) == order);
            String displayId = order.id.padLeft(4, '0');
            String address = _getAddress(order.customerName);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 2,
              child: ExpansionTile(
                key: Key(order.id + (_expandedOrderId == order.id).toString()),
                initiallyExpanded: _expandedOrderId == order.id,
                onExpansionChanged: (isOpen) {
                  if (isOpen) setState(() => _expandedOrderId = order.id);
                },
                tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)), child: Text(displayId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13))), const SizedBox(height: 4), Text(DateFormat('dd MMM').format(order.date), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), if(address.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Row(children: [const Icon(Icons.location_on, size: 12, color: Colors.grey), const SizedBox(width: 2), Expanded(child: Text(address, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis))]))])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("₹${order.totalAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)), const SizedBox(height: 5), InkWell(onTap: () => widget.onDelete(context, box, key), child: const Icon(Icons.delete_outline, size: 20, color: Colors.red))])
                  ],
                ),
                children: [
                  _InlineOrderProcessor(order: order, orderKey: key, onDelete: () => widget.onDelete(context, box, key)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- WIDGET: INLINE ORDER PROCESSOR ---
class _InlineOrderProcessor extends StatefulWidget {
  final OrderModel order;
  final dynamic orderKey;
  final VoidCallback onDelete;

  const _InlineOrderProcessor({required this.order, required this.orderKey, required this.onDelete});

  @override
  State<_InlineOrderProcessor> createState() => _InlineOrderProcessorState();
}

class _InlineOrderProcessorState extends State<_InlineOrderProcessor> {
  late List<CartItem> _items;
  double _liveTotal = 0;

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  void _initItems() {
    _items = widget.order.items.map((item) {
      int safeOriginal = item.originalQty == 0 ? item.quantity : item.originalQty;
      return CartItem(product: item.product, quantity: item.quantity, sellPrice: item.sellPrice, scheme: item.scheme, discount: item.discount, remark: item.remark, uom: item.uom, isAccepted: item.isAccepted, originalQty: safeOriginal);
    }).toList();
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      if (item.isAccepted) total += item.total;
    }
    setState(() => _liveTotal = total);
  }

  void _updateItem(int index, {int? qty, double? price, bool? accepted, String? scheme, double? discount, String? uom}) {
    final old = _items[index];
    final newItem = CartItem(
      product: old.product, quantity: qty ?? old.quantity, sellPrice: price ?? old.sellPrice, scheme: scheme ?? old.scheme, discount: discount ?? old.discount, remark: old.remark, uom: uom ?? old.uom, isAccepted: accepted ?? old.isAccepted, originalQty: old.originalQty,
    );
    setState(() => _items[index] = newItem);
    _calculateTotal();
  }

  void _saveAndApprove() async {
    final box = Hive.box<OrderModel>('orders_v2');
    bool hasItems = _items.any((i) => i.isAccepted && i.quantity > 0);

    final updatedOrder = OrderModel(
      id: widget.order.id, 
      customerName: widget.order.customerName,
      customerPhone: widget.order.customerPhone,
      date: widget.order.date,
      totalAmount: _liveTotal, 
      discount: widget.order.discount,
      items: _items,
      isApproved: true, 
    );

    await box.put(widget.orderKey, updatedOrder);

    if (!mounted) return;

    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Rejected (Moved to Pending List)"), backgroundColor: Colors.orange));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Approved!")));
      int? seqId = int.tryParse(widget.order.id);
      final file = await PdfService().generatePdfFile(_items.where((i) => i.isAccepted && i.quantity > 0).toList(), _liveTotal, widget.order.id, widget.order.customerName, sequenceNumber: seqId ?? 1);
      await PdfService().openPdf(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8), color: Colors.grey.shade100, child: const Row(children: [SizedBox(width: 25, child: Text("#", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(flex: 3, child: Text("Item", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 35, child: Text("Qty", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 50, child: Text("Unit", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 45, child: Text("Rate", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 35, child: Text("Sch", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 35, child: Text("Dsc", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 25, child: Text("Ok", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center))])),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              bool isShortage = item.quantity < item.originalQty;
              double standardRate = item.product.price;
              if (item.uom == item.product.secondaryUom) { standardRate = (item.product.price2 != null && item.product.price2! > 0) ? item.product.price2! : item.product.price * (item.product.conversionFactor ?? 1); }
              bool isRateModified = (item.sellPrice - standardRate).abs() > 0.1;

              return Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 25, child: Padding(padding: const EdgeInsets.only(top: 8), child: Text("${index + 1}.", style: const TextStyle(fontSize: 11)))),
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, decoration: !item.isAccepted ? TextDecoration.lineThrough : null, color: !item.isAccepted ? Colors.grey : Colors.black)), if (item.isAccepted) Text("₹${item.total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))])),
                    if (item.isAccepted) ...[
                      // QTY - FIXED using _HistoryMiniInput
                      _HistoryMiniInput(value: "${item.quantity}", width: 35, isNumeric: true, onChanged: (v)=>_updateItem(index, qty: int.tryParse(v)??0)), const SizedBox(width: 4),
                      
                      // UNIT DROPDOWN
                      _buildUnitDropdown(item, index, (val) { 
                         double newPrice;
                         if (val == widget.order.items[index].uom) {
                           newPrice = widget.order.items[index].sellPrice;
                         } else {
                           newPrice = (val == item.product.secondaryUom) 
                              ? (item.product.price2 ?? item.product.price * (item.product.conversionFactor ?? 1)) 
                              : item.product.price; 
                         }
                         _updateItem(index, uom: val, price: newPrice); 
                      }), const SizedBox(width: 4),
                      
                      // RATE - FIXED using _HistoryMiniInput
                      Column(children: [
                        _HistoryMiniInput(value: "${item.sellPrice.toStringAsFixed(0)}", width: 45, isNumeric: true, onChanged: (v)=>_updateItem(index, price: double.tryParse(v)??0)), 
                        if(isRateModified) Text("${standardRate.toStringAsFixed(0)}", style: const TextStyle(fontSize: 8, color: Colors.red, decoration: TextDecoration.lineThrough))
                      ]),
                      
                      // SCHEME & DISC - FIXED using _HistoryMiniInput
                      _HistoryMiniInput(value: item.scheme, width: 35, onChanged: (v)=>_updateItem(index, scheme: v)), 
                      _HistoryMiniInput(value: item.discount > 0 ? "${item.discount}" : "", width: 35, isNumeric: true, onChanged: (v)=>_updateItem(index, discount: double.tryParse(v)??0)),
                    ] else ...[const Expanded(flex: 5, child: Text("Rejected", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic)))],
                    SizedBox(width: 25, height: 30, child: Checkbox(value: item.isAccepted, onChanged: (v) => _updateItem(index, accepted: v), activeColor: Colors.blue, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
                  ],
                ),
              );
            }
          ),
          Padding(padding: const EdgeInsets.all(12.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total: ₹${_liveTotal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)), ElevatedButton.icon(onPressed: _saveAndApprove, icon: const Icon(Icons.check_circle, size: 18), label: const Text("APPROVE"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white))])),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(CartItem item, int index, Function(String) onChanged) {
    if (item.product.secondaryUom == null || item.product.secondaryUom!.isEmpty) return SizedBox(width: 50, child: Center(child: Text(item.uom, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))));
    return Container(width: 50, height: 30, padding: EdgeInsets.zero, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: item.uom, isDense: true, iconSize: 14, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black), items: [DropdownMenuItem(value: item.product.uom, child: Text(item.product.uom)), DropdownMenuItem(value: item.product.secondaryUom, child: Text(item.product.secondaryUom!))], onChanged: (v) { if(v!=null && v!=item.uom) onChanged(v); })));
  }

  // OLD _buildMiniField removed, new class used below
}

// ==========================================
// TAB 2: PENDING ITEMS (UNCHANGED)
// ==========================================
class _ItemWisePendingTab extends StatefulWidget {
  const _ItemWisePendingTab();

  @override
  State<_ItemWisePendingTab> createState() => _ItemWisePendingTabState();
}

class _ItemWisePendingTabState extends State<_ItemWisePendingTab> {
  String? _expandedProduct;

  void _removePendingItem(Box<OrderModel> box, dynamic orderKey, int itemIndex) async {
    final OrderModel? order = box.get(orderKey);
    if(order == null) return;
    final updatedItems = List<CartItem>.from(order.items);
    final oldItem = updatedItems[itemIndex];
    updatedItems[itemIndex] = CartItem(product: oldItem.product, quantity: oldItem.quantity, sellPrice: oldItem.sellPrice, scheme: oldItem.scheme, discount: oldItem.discount, uom: oldItem.uom, isAccepted: oldItem.isAccepted, originalQty: oldItem.originalQty, remark: "{REORDERED} ${oldItem.remark}");
    final updatedOrder = OrderModel(id: order.id, customerName: order.customerName, customerPhone: order.customerPhone, date: order.date, totalAmount: order.totalAmount, discount: order.discount, items: updatedItems, isApproved: true);
    await box.put(orderKey, updatedOrder);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<OrderModel>('orders_v2').listenable(),
      builder: (context, Box<OrderModel> box, _) {
        Map<String, List<Map<String, dynamic>>> productGrouped = {};
        for (var key in box.keys) {
          final order = box.get(key)!;
          if (!order.isApproved) continue; 
          for (int j = 0; j < order.items.length; j++) {
            final item = order.items[j];
            if (item.remark.contains("{REORDERED}")) continue;
            
            bool isRejected = (!item.isAccepted);
            int safeOriginal = item.originalQty == 0 ? item.quantity : item.originalQty;
            bool isPartial = (item.isAccepted && item.quantity < safeOriginal);

            if (isPartial || isRejected) {
              if (!productGrouped.containsKey(item.product.name)) productGrouped[item.product.name] = [];
              int shortage = isRejected ? safeOriginal : (safeOriginal - item.quantity);
              productGrouped[item.product.name]!.add({'customer': order.customerName, 'shortage': shortage, 'uom': item.uom, 'date': order.date, 'product': item.product, 'rate': item.sellPrice, 'originalOrderKey': key, 'itemIndex': j});
            }
          }
        }
        if (productGrouped.isEmpty) return const Center(child: Text("No Pending Items"));
        
        return ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: productGrouped.length,
          itemBuilder: (context, index) {
            String productName = productGrouped.keys.elementAt(index);
            List<Map<String, dynamic>> entries = productGrouped[productName]!;
            int totalShortage = entries.fold(0, (sum, e) => sum + (e['shortage'] as int));
            String uom = entries.first['uom'];
            return Card(child: ExpansionTile(key: Key(productName + (_expandedProduct==productName).toString()), initiallyExpanded: _expandedProduct==productName, onExpansionChanged: (v){if(v)setState(()=>_expandedProduct=productName);}, backgroundColor: Colors.white, leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: Text("$totalShortage", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))), title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("$totalShortage $uom total pending"), children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.grey.shade100, child: const Row(children: [SizedBox(width: 30, child: Text("No.", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 50, child: Text("Date", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(child: Text("Customer", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 50, child: Text("Qty", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))), SizedBox(width: 60, child: Text("Action", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))])),
              ...entries.asMap().entries.map((entry) {
                int idx = entry.key + 1; var data = entry.value;
                return Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [SizedBox(width: 30, child: Text("$idx.", style: const TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 50, child: Text(DateFormat('dd/MM').format(data['date']), style: const TextStyle(fontSize: 12))), Expanded(child: Text(data['customer'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)), SizedBox(width: 50, child: Text("${data['shortage']} ${data['uom']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12))), SizedBox(width: 60, child: Row(children: [InkWell(onTap: () => _createReOrder(context, data['customer'], data['product'], data['shortage'], data['uom'], data['rate'], data['originalOrderKey'], data['itemIndex']), child: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.green)), const SizedBox(width: 10), InkWell(onTap: () => _removePendingItem(box, data['originalOrderKey'], data['itemIndex']), child: const Icon(Icons.close, size: 20, color: Colors.grey))]))]));
              }),
            ]));
          },
        );
      },
    );
  }
}

// ==========================================
// TAB 3: APPROVED ORDERS (UNCHANGED)
// ==========================================
class _ApprovedOrdersTab extends StatefulWidget {
  final Function(BuildContext, Box<OrderModel>, dynamic) onDelete;
  final OrderSort sort;
  const _ApprovedOrdersTab({required this.onDelete, required this.sort});

  @override
  State<_ApprovedOrdersTab> createState() => _ApprovedOrdersTabState();
}

class _ApprovedOrdersTabState extends State<_ApprovedOrdersTab> {
  String? _expandedOrderId;

  void _openPdf(BuildContext context, OrderModel order) async {
    final pdfService = PdfService();
    final validItems = order.items.where((i) => i.isAccepted && i.quantity > 0).toList();
    if(validItems.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No items to print!"))); return; }
    int seqId = int.tryParse(order.id) ?? 0;
    final file = await pdfService.generatePdfFile(validItems, order.totalAmount, order.id, order.customerName, sequenceNumber: seqId);
    await pdfService.openPdf(file);
  }

  List<OrderModel> _sortOrders(List<OrderModel> list) {
    switch (widget.sort) {
      case OrderSort.dateNewest: list.sort((a, b) => b.date.compareTo(a.date)); break;
      case OrderSort.dateOldest: list.sort((a, b) => a.date.compareTo(b.date)); break;
      case OrderSort.amountHigh: list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount)); break;
      case OrderSort.amountLow: list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount)); break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<OrderModel>('orders_v2').listenable(),
      builder: (context, Box<OrderModel> box, _) {
        var orders = box.values.where((o) => o.isApproved && o.items.any((i) => i.isAccepted && i.quantity > 0)).toList();
        orders = _sortOrders(orders);

        if (orders.isEmpty) return const Center(child: Text("No Approved Orders", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final key = box.keys.firstWhere((k) => box.get(k) == order);
            String displayId = order.id.padLeft(4, '0');

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: ExpansionTile(
                key: Key(order.id + (_expandedOrderId == order.id).toString()),
                initiallyExpanded: _expandedOrderId == order.id,
                onExpansionChanged: (isOpen) {
                  if (isOpen) setState(() => _expandedOrderId = order.id);
                },
                title: Row(children: [Text(displayId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)), Text(DateFormat('dd MMM').format(order.date), style: const TextStyle(color: Colors.grey, fontSize: 11))])), Text("₹${order.totalAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), const SizedBox(width: 5), const Icon(Icons.check_circle, color: Colors.green, size: 18)]),
                children: [
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), color: Colors.grey.shade100, child: const Row(children: [SizedBox(width: 25, child: Text("S.No", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), Expanded(flex: 3, child: Text("Item", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 35, child: Text("Qty", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 35, child: Text("Unit", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 45, child: Text("Rate", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 35, child: Text("Sch", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 40, child: Text("Amt", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right))])),
                        ...order.items.where((i) => i.isAccepted && i.quantity > 0).toList().asMap().entries.map((entry) {
                          int idx = entry.key + 1; var item = entry.value;
                          return Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Row(children: [SizedBox(width: 25, child: Text("$idx.", style: const TextStyle(fontSize: 12))), Expanded(flex: 3, child: Text(item.product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))), SizedBox(width: 35, child: Text("${item.quantity}", style: const TextStyle(fontSize: 12))), SizedBox(width: 35, child: Text(item.uom, style: const TextStyle(fontSize: 12))), SizedBox(width: 45, child: Text("${item.sellPrice.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12))), SizedBox(width: 35, child: Text(item.scheme, style: const TextStyle(fontSize: 11))), SizedBox(width: 40, child: Text("${item.total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right))]));
                        }),
                        const Divider(),
                        Padding(padding: const EdgeInsets.all(8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text("View Invoice"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), onPressed: () => _openPdf(context, order)), ElevatedButton.icon(icon: const Icon(Icons.delete, size: 18), label: const Text("Delete"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => widget.onDelete(context, box, key))])),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- HELPER: CREATE RE-ORDER (UNCHANGED) ---
void _createReOrder(BuildContext context, String custName, ProductModel product, int qty, String uom, double rate, dynamic originalKey, int itemIndex) async {
  final orderBox = Hive.box<OrderModel>('orders_v2');
  final custBox = Hive.box<CustomerModel>('customers_v2');
  final customer = custBox.values.firstWhere((c) => c.name == custName, orElse: () => CustomerModel(id: '', name: custName, phone: '', address: ''));
  int maxId = 0;
  for (var o in orderBox.values) {
    int? cid = int.tryParse(o.id);
    if (cid != null && cid < 900000 && cid > maxId) maxId = cid;
  }
  String nextId = (maxId + 1).toString();
  final newItem = CartItem(product: product, quantity: qty, sellPrice: rate, uom: uom, originalQty: qty, scheme: "", discount: 0, remark: "Refill");
  final newOrder = OrderModel(id: nextId, customerName: customer.name, customerPhone: customer.phone, date: DateTime.now(), totalAmount: newItem.total, discount: 0, items: [newItem], isApproved: false);
  await orderBox.add(newOrder);
  final OrderModel? freshOldOrder = orderBox.get(originalKey);
  if (freshOldOrder != null) {
    final updatedItems = List<CartItem>.from(freshOldOrder.items);
    final oldItem = updatedItems[itemIndex];
    updatedItems[itemIndex] = CartItem(product: oldItem.product, quantity: oldItem.quantity, sellPrice: oldItem.sellPrice, scheme: oldItem.scheme, discount: oldItem.discount, remark: "{REORDERED} ${oldItem.remark}", uom: oldItem.uom, isAccepted: oldItem.isAccepted, originalQty: oldItem.originalQty);
    final updatedOrderObj = OrderModel(id: freshOldOrder.id, customerName: freshOldOrder.customerName, customerPhone: freshOldOrder.customerPhone, date: freshOldOrder.date, totalAmount: freshOldOrder.totalAmount, discount: freshOldOrder.discount, items: updatedItems, isApproved: true);
    await orderBox.put(originalKey, updatedOrderObj);
  }
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Re-Order Created!"), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
}

// --- NEW STABLE MINI FIELD (Fixes Focus Jump) ---
class _HistoryMiniInput extends StatefulWidget {
  final String value;
  final double width;
  final bool isNumeric;
  final Function(String) onChanged;

  const _HistoryMiniInput({required this.value, required this.width, required this.onChanged, this.isNumeric = false});

  @override
  State<_HistoryMiniInput> createState() => _HistoryMiniInputState();
}

class _HistoryMiniInputState extends State<_HistoryMiniInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_HistoryMiniInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (_ctrl.text != widget.value) {
         if (widget.isNumeric) {
             if (double.tryParse(_ctrl.text) != double.tryParse(widget.value)) {
                 _ctrl.text = widget.value;
             }
         } else {
             _ctrl.text = widget.value;
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width, height: 30, margin: const EdgeInsets.symmetric(horizontal: 1),
      child: TextFormField(
        controller: _ctrl, // Uses controller to keep focus
        keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8), border: OutlineInputBorder(), isDense: true),
        onChanged: widget.onChanged,
      ),
    );
  }
}