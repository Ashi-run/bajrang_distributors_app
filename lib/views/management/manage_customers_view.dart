import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/data_repository.dart';

class ManageCustomersView extends StatefulWidget {
  const ManageCustomersView({super.key});

  @override
  State<ManageCustomersView> createState() => _ManageCustomersViewState();
}

class _ManageCustomersViewState extends State<ManageCustomersView> {
  final DataRepository _repo = DataRepository();
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  // Theme
  final Color _brandBlue = const Color(0xFF1A237E); 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final data = _repo.getAllCustomers();
    // Sort A-Z
    data.sort((a,b) => a.name.compareTo(b.name));
    setState(() {
      _customers = data;
      _filtered = data;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _customers;
      } else {
        _filtered = _customers.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _showAddOptions() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.edit, color: Colors.blue), title: const Text("Add Manually"), onTap: () {Navigator.pop(ctx); _showDialog();}), ListTile(leading: const Icon(Icons.file_upload, color: Colors.green), title: const Text("Import from Excel"), onTap: () async {Navigator.pop(ctx); try {String res = await _repo.importCustomerData(); if (mounted) {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res))); _loadData();}} catch (e) {if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));}}),])));
  }

  void _showDialog({CustomerModel? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? "");
    final phoneCtrl = TextEditingController(text: customer?.phone ?? "");
    final addrCtrl = TextEditingController(text: customer?.address ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(customer == null ? "Add Customer" : "Edit Customer"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")), TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")), TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: "Address"))]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            final newCust = CustomerModel(id: customer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text, phone: phoneCtrl.text, address: addrCtrl.text);
            if (customer == null) await _repo.addCustomer(newCust); else await _repo.updateCustomer(newCust);
            if (mounted) { Navigator.pop(ctx); _loadData(); }
          }, child: const Text("Save"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Manage Customers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: _brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Styled Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search Customers...",
                prefixIcon: Icon(Icons.search, color: _brandBlue),
                filled: true,
                fillColor: const Color(0xFFE8EAF6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: _search,
            ),
          ),
          
          Expanded(
            child: _filtered.isEmpty 
            ? const Center(child: Text("No customers found", style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final c = _filtered[i];
                  return Container(
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: _brandBlue.withOpacity(0.1),
                        child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : "?", style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${c.phone} | ${c.address}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(customer: c)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { await _repo.deleteCustomer(c.id); _loadData(); }),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }
}