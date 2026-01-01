import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/order_model.dart';

// --- YOUR CORRECT IMPORTS ---
import '../management/manage_products_view.dart';
import '../management/manage_customers_view.dart';

import '../catalog/catalog_view.dart';
import '../history/order_history_view.dart';
import '../catalog/read_only_catalog_view.dart';
import '../reports/reports_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.store, color: Color(0xFF1565C0)),
            SizedBox(width: 10),
            Text("About App", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bajrang Distributors App", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),
            Text("Developed by", style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 4),
            Text("Ashi Sharma", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            SizedBox(height: 4),
            Text("© 2025 All Rights Reserved", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMastersMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Master Data Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1565C0))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMasterOption(
                    context, 
                    "Products", 
                    Icons.inventory_2, 
                    Colors.orange, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductsView()))
                  ),
                  _buildMasterOption(
                    context, 
                    "Customers", 
                    Icons.people_alt, 
                    Colors.blue, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCustomersView()))
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterOption(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); 
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1565C0);
    final Color bgGrey = const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        const Text("Bajrang Distributors", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showAboutDialog(context),
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 20,
                        child: Icon(Icons.info_outline, color: Colors.white, size: 24),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 25),
                // --- LIVE STATS SECTION ---
                _buildQuickStats(context),
              ],
            ),
          ),

          // --- MAIN GRID ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(context, "Place Order", Icons.shopping_cart_checkout, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BajrangCatalog()))),
                  _buildMenuCard(context, "Order History", Icons.history, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryView(initialIndex: 0)))),
                  _buildMenuCard(context, "Price List", Icons.menu_book, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadOnlyCatalogView()))),
                  _buildMenuCard(context, "Reports", Icons.bar_chart, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsView()))),
                ],
              ),
            ),
          ),

          // --- MASTERS BOTTOM BAR (SAFE AREA) ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              top: false,
              child: InkWell(
                onTap: () => _showMastersMenu(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, color: primaryBlue),
                      const SizedBox(width: 10),
                      Text("MASTERS & SETTINGS", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                      const SizedBox(width: 5),
                      Icon(Icons.keyboard_arrow_up, color: primaryBlue, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FIXED LIVE STATS ---
  Widget _buildQuickStats(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<OrderModel>('orders_v2').listenable(),
      builder: (context, Box<OrderModel> box, _) {
        final today = DateTime.now();
        
        // 1. Calculate Today's Orders
        final todayOrders = box.values.where((o) => 
          o.date.year == today.year && 
          o.date.month == today.month && 
          o.date.day == today.day
        ).toList();
        
        // 2. Calculate Pending Orders (Robust Logic)
        int pendingCount = 0;
        for (var order in box.values) {
          // Condition 1: Order is not approved yet (Pending)
          if (!order.isApproved) {
            pendingCount++;
          } else {
            // Condition 2: Order is approved but has rejected/partial items
            // (Optional: You can remove this 'else' block if you ONLY want to count unapproved orders)
            bool hasIssues = false;
            for (var item in order.items) {
               // Safe Null Check Added (?? "")
               if ((item.remark ?? "").contains("{REORDERED}")) continue;
               
               int safeOriginal = item.originalQty == 0 ? item.quantity : item.originalQty;
               bool isRejected = !item.isAccepted;
               bool isPartial = item.isAccepted && item.quantity < safeOriginal;
               
               if (isRejected || isPartial) {
                 hasIssues = true;
                 break; 
               }
            }
            if (hasIssues) pendingCount++;
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildClickableStatItem(
                context, 
                "${todayOrders.length}", 
                "Today's Orders", 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryView(initialIndex: 0)))
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildClickableStatItem(
                context, 
                "$pendingCount", 
                "Pending Actions", 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryView(initialIndex: 1)))
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClickableStatItem(BuildContext context, String value, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}