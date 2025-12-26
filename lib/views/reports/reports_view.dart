import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String _selectedFilter = "This Week"; // Options: Today, This Week, This Month

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<OrderModel>('orders_v2');
    final allOrders = box.values.where((o) => o.isApproved).toList();

    // 1. FILTER DATA
    List<OrderModel> filteredOrders = _filterOrders(allOrders);

    // 2. CALCULATE STATS
    double totalRevenue = filteredOrders.fold(0, (sum, o) => sum + o.totalAmount);
    int totalOrders = filteredOrders.length;
    double avgOrderValue = totalOrders == 0 ? 0 : totalRevenue / totalOrders;

    // 3. TOP PRODUCTS
    Map<String, int> productSales = {};
    for (var order in filteredOrders) {
      for (var item in order.items) {
        if (item.isAccepted) {
          productSales[item.product.name] = (productSales[item.product.name] ?? 0) + item.quantity;
        }
      }
    }
    var topProducts = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 4. TOP CUSTOMERS (New Insight)
    Map<String, double> customerSpending = {};
    for (var order in filteredOrders) {
      customerSpending[order.customerName] = (customerSpending[order.customerName] ?? 0) + order.totalAmount;
    }
    var topCustomers = customerSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Reports & Insights", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              dropdownColor: Colors.indigo,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.filter_list, color: Colors.white),
              items: ["Today", "This Week", "This Month"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedFilter = val!),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI ROW
            Row(
              children: [
                _buildKpiCard("Revenue", "₹${totalRevenue.toStringAsFixed(0)}", Colors.green, Icons.currency_rupee),
                const SizedBox(width: 10),
                _buildKpiCard("Orders", "$totalOrders", Colors.blue, Icons.shopping_bag),
                const SizedBox(width: 10),
                _buildKpiCard("Avg Value", "₹${avgOrderValue.toStringAsFixed(0)}", Colors.orange, Icons.analytics),
              ],
            ),

            const SizedBox(height: 25),

            // SALES TREND GRAPH
            const Text("Sales Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
              child: _buildSimpleBarChart(filteredOrders),
            ),

            const SizedBox(height: 25),

            // INSIGHTS ROW (Top Products & Top Customers)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRankingList("Top Products", topProducts, true)),
                const SizedBox(width: 15),
                Expanded(child: _buildRankingList("Top Customers", topCustomers, false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildRankingList(String title, List<MapEntry> data, bool isProduct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length > 5 ? 5 : data.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final entry = data[i];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                trailing: Text(
                  isProduct ? "${entry.value}" : "₹${(entry.value as double).toStringAsFixed(0)}", 
                  style: TextStyle(color: isProduct ? Colors.blue : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    return orders.where((order) {
      if (_selectedFilter == "Today") {
        return order.date.isAfter(today);
      } else if (_selectedFilter == "This Week") {
        DateTime weekAgo = now.subtract(const Duration(days: 7));
        return order.date.isAfter(weekAgo);
      } else {
        DateTime monthStart = DateTime(now.year, now.month, 1);
        return order.date.isAfter(monthStart);
      }
    }).toList();
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(bottom: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart(List<OrderModel> orders) {
    Map<int, double> dailySales = {};
    for (var i = 0; i < 7; i++) dailySales[i] = 0; 

    for (var order in orders) {
      int diff = DateTime.now().difference(order.date).inDays;
      if (diff < 7 && diff >= 0) {
        dailySales[diff] = (dailySales[diff] ?? 0) + order.totalAmount;
      }
    }

    double maxVal = dailySales.values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        int dayIndex = 6 - index;
        double heightPct = (dailySales[dayIndex] ?? 0) / maxVal;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text((dailySales[dayIndex] ?? 0) > 0 ? "₹${(dailySales[dayIndex]!/1000).toStringAsFixed(1)}k" : "", style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            Container(
              width: 25,
              height: 120 * heightPct + 5, 
              decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 5),
            Text(DateFormat('E').format(DateTime.now().subtract(Duration(days: dayIndex))), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        );
      }),
    );
  }
}