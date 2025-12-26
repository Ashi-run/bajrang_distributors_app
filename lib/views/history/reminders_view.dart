import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/customer_model.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Stock Reminders", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1A237E),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Pending Items"),
              Tab(text: "Rejected Items"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GroupedList(isPending: true),
            _GroupedList(isPending: false),
          ],
        ),
      ),
    );
  }
}

class _GroupedList extends StatefulWidget {
  final bool isPending;
  const _GroupedList({required this.isPending});

  @override
  State<_GroupedList> createState() => _GroupedListState();
}

class _GroupedListState extends State<_GroupedList> {
  
  void _markAsDone(int orderKey, OrderModel order, int itemIndex) async {
    final box = Hive.box<OrderModel>('orders_v2');
    List<CartItem> updatedItems = List.from(order.items);
    final oldItem = updatedItems[itemIndex];

    updatedItems[itemIndex] = CartItem(
      product: oldItem.product,
      quantity: oldItem.originalQty,
      sellPrice: oldItem.sellPrice,
      scheme: oldItem.scheme, // Now correctly copies String
      discount: oldItem.discount,
      remark: oldItem.remark,
      uom: oldItem.uom,
      isAccepted: true,
      originalQty: oldItem.originalQty,
    );

    final updatedOrder = OrderModel(
      id: order.id,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      date: order.date,
      totalAmount: _recalculateTotal(updatedItems),
      discount: order.discount,
      items: updatedItems,
      isApproved: order.isApproved,
    );

    await box.put(orderKey, updatedOrder);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Marked as Delivered!")));
  }

  double _recalculateTotal(List<CartItem> items) {
    double total = 0;
    for (var item in items) {
      if (item.isAccepted) total += item.total;
    }
    return total;
  }

  String _getCustomerAddress(String customerName) {
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<OrderModel>('orders_v2').listenable(),
      builder: (context, Box<OrderModel> box, _) {
        Map<String, List<Map<String, dynamic>>> groupedItems = {};

        for (var key in box.keys) {
          final order = box.get(key)!;
          for (int i = 0; i < order.items.length; i++) {
            final item = order.items[i];
            bool condition = widget.isPending 
                ? (item.isAccepted && item.quantity < item.originalQty) 
                : (!item.isAccepted); 

            if (condition) {
              if (!groupedItems.containsKey(item.product.name)) {
                groupedItems[item.product.name] = [];
              }
              groupedItems[item.product.name]!.add({
                'orderKey': key,
                'order': order,
                'itemIndex': i,
                'item': item,
              });
            }
          }
        }

        if (groupedItems.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline, size: 60, color: Colors.green), const SizedBox(height: 10), Text(widget.isPending ? "No Pending Items" : "No Rejected Items")]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: groupedItems.length,
          itemBuilder: (ctx, i) {
            String productName = groupedItems.keys.elementAt(i);
            List<Map<String, dynamic>> requests = groupedItems[productName]!;
            
            int totalQty = 0;
            for(var r in requests) {
              CartItem it = r['item'];
              totalQty += (it.originalQty - it.quantity);
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(
                  widget.isPending ? "Total Pending: $totalQty units" : "Rejected in ${requests.length} orders",
                  style: TextStyle(color: widget.isPending ? Colors.orange[800] : Colors.red, fontWeight: FontWeight.bold),
                ),
                leading: CircleAvatar(
                  backgroundColor: widget.isPending ? Colors.orange.shade50 : Colors.red.shade50,
                  child: Icon(widget.isPending ? Icons.timelapse : Icons.cancel, color: widget.isPending ? Colors.orange : Colors.red),
                ),
                children: requests.map((req) {
                  OrderModel order = req['order'];
                  CartItem item = req['item'];
                  int count = item.originalQty - item.quantity;
                  String address = _getCustomerAddress(order.customerName);

                  return Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (address.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(address, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                                ],
                              ),
                            ),
                          Text(DateFormat('dd MMM yyyy').format(order.date), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(widget.isPending ? "Owe: $count" : "Rejected", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              Text(item.uom, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            onPressed: () => _markAsDone(req['orderKey'], order, req['itemIndex']),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}