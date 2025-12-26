import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../core/services/pdf_service.dart';

class ProcessOrderView extends StatefulWidget {
  final OrderModel order;
  final dynamic orderKey; 

  const ProcessOrderView({super.key, required this.order, required this.orderKey});

  @override
  State<ProcessOrderView> createState() => _ProcessOrderViewState();
}

class _ProcessOrderViewState extends State<ProcessOrderView> {
  late List<CartItem> _items;
  double _liveTotal = 0;

  @override
  void initState() {
    super.initState();
    _items = widget.order.items.map((item) {
      int safeOriginal = item.originalQty == 0 ? item.quantity : item.originalQty;
      return CartItem(
        product: item.product, quantity: item.quantity, sellPrice: item.sellPrice, scheme: item.scheme, discount: item.discount, remark: item.remark, uom: item.uom, isAccepted: item.isAccepted, originalQty: safeOriginal 
      );
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

  void _updateItem(int index, {int? qty, double? price, bool? accepted, String? scheme, double? discount}) {
    final old = _items[index];
    final newItem = CartItem(
      product: old.product, quantity: qty ?? old.quantity, sellPrice: price ?? old.sellPrice, scheme: scheme ?? old.scheme, discount: discount ?? old.discount, remark: old.remark, uom: old.uom, isAccepted: accepted ?? old.isAccepted, originalQty: old.originalQty,
    );
    setState(() => _items[index] = newItem);
    _calculateTotal();
  }

  void _saveAndApprove() async {
    final box = Hive.box<OrderModel>('orders_v2');
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Processed & Saved!")));
    
    // GENERATE FILE & OPEN
    int? seqId = int.tryParse(widget.order.id);
    final file = await PdfService().generatePdfFile(_items.where((i) => i.isAccepted && i.quantity > 0).toList(), _liveTotal, widget.order.id, widget.order.customerName, sequenceNumber: seqId ?? 1);
    await PdfService().openPdf(file);
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Process Order #${widget.order.id.padLeft(4, '0')}"), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(16), color: const Color(0xFFE8EAF6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("ORDER TOTAL:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("₹ ${_liveTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1A237E)))])),
        Expanded(child: ListView.builder(itemCount: _items.length, itemBuilder: (context, index) {
          final item = _items[index];
          bool isShortage = item.quantity < item.originalQty;
          int pendingQty = item.originalQty - item.quantity;
          
          return Card(
            color: item.isAccepted ? Colors.white : Colors.red.shade50,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SizedBox(width: 25, child: Text("${index + 1}.")),
                Expanded(child: Text(item.product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: !item.isAccepted ? TextDecoration.lineThrough : null))),
                if (item.isAccepted) Text("₹${item.total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                const SizedBox(width: 5),
                Checkbox(value: item.isAccepted, onChanged: (val) => _updateItem(index, accepted: val), activeColor: const Color(0xFF1A237E)), 
              ]),
              if (item.isAccepted) ...[
                const Divider(),
                if (isShortage) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)), child: Row(children: [const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.deepOrange), const SizedBox(width: 5), Text("Partial: ${item.quantity}/${item.originalQty}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange)), const Spacer(), Text("$pendingQty Pending", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red))])),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.end, children: [
                  _buildEditableField("Qty", "${item.quantity}", 50, (v) => _updateItem(index, qty: int.tryParse(v) ?? 0)),
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(item.uom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  _buildEditableField("Rate", "${item.sellPrice}", 70, (v) => _updateItem(index, price: double.tryParse(v) ?? 0.0)),
                  _buildEditableField("Scheme", item.scheme, 60, (v) => _updateItem(index, scheme: v), isText: true),
                  _buildEditableField("Disc", item.discount == 0 ? "" : "${item.discount}", 50, (v) => _updateItem(index, discount: double.tryParse(v) ?? 0.0)),
                ]),
              ] else const Padding(padding: EdgeInsets.only(top: 5), child: Text("Item Rejected ❌", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)))
            ])),
          );
        })),
        Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(icon: const Icon(Icons.print), label: const Text("SAVE & PRINT INVOICE"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white), onPressed: _saveAndApprove)))
      ])
    );
  }

  Widget _buildEditableField(String label, String val, double width, Function(String) onChanged, {bool isText = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), SizedBox(width: width, height: 35, child: TextFormField(initialValue: val, keyboardType: isText ? TextInputType.text : TextInputType.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5), border: OutlineInputBorder(), isDense: true), onChanged: onChanged))]);
  }
}