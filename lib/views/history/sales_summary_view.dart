import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../../data/models/cart_item_model.dart';

class SalesSummaryView extends StatefulWidget {
  const SalesSummaryView({super.key});

  @override
  State<SalesSummaryView> createState() => _SalesSummaryViewState();
}

class _SalesSummaryViewState extends State<SalesSummaryView> {
  String _selectedFilter = "This Week"; // Options: Today, This Week, This Month

  @override
  Widget build(BuildContext context) {
    // FIX: Ensure we use 'orders_v2' to avoid "Box not found"
    final box = Hive.box<OrderModel>('orders_v2'); 
    final allOrders = box.values.where((o) => o.isApproved).toList();

    // 1. FILTER DATA
    List<OrderModel> filteredOrders = _filterOrders(allOrders);

    // 2. CALCULATE STATS
    double totalRevenue = filteredOrders.fold(0, (sum, o) => sum + o.totalAmount);
    int totalOrders = filteredOrders.length;
    double avgOrderValue = totalOrders == 0 ? 0 : totalRevenue / totalOrders;

    // 3. TOP PRODUCTS CALCULATION
    Map<String, int> productSales = {};
    for (var order in filteredOrders) {
      for (var item in order.items) {
        if (item.isAccepted) {
          productSales[item.product.name] = (productSales[item.product.name] ?? 0) + item.quantity;
        }
      }
    }
    var topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort Descending

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Business Dashboard"),
        elevation: 0,
        actions: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: DropdownButton<String>(
              value: _selectedFilter,
              dropdownColor: Colors.blue,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.filter_list, color: Colors.white),
              underline: Container(),
              items: ["Today", "This Week", "This Month"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedFilter = val!),
            ),
          )
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

            const SizedBox(height: 20),

            // CHART SECTION (Sales Trend)
            const Text("Sales Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: _buildSimpleBarChart(filteredOrders),
            ),

            const SizedBox(height: 20),

            // TOP PRODUCTS LIST
            const Text("Top Selling Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length > 5 ? 5 : topProducts.length, // Show max 5
              itemBuilder: (context, index) {
                final entry = topProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text("${entry.value} Sold", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER METHODS ---

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
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // Simple Custom Bar Chart (No Package Needed)
  Widget _buildSimpleBarChart(List<OrderModel> orders) {
    // Group sales by day
    Map<int, double> dailySales = {};
    for (var i = 0; i < 7; i++) dailySales[i] = 0; // Init 0 for last 7 days

    for (var order in orders) {
      // Calculate difference in days from today (0 = today, 1 = yesterday...)
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
        // Reverse index to show Today on right (index 0)
        int dayIndex = 6 - index;
        double heightPct = (dailySales[dayIndex] ?? 0) / maxVal;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text((dailySales[dayIndex] ?? 0) > 0 ? "₹${(dailySales[dayIndex]!/1000).toStringAsFixed(1)}k" : "", style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 5),
            Container(
              width: 20,
              height: 100 * heightPct + 5, // Min height 5
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 5),
            Text(DateFormat('E').format(DateTime.now().subtract(Duration(days: dayIndex))), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        );
      }),
    );
  }
}