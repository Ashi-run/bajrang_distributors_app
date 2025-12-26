import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/data_repository.dart';

class AddCustomerView extends StatefulWidget {
  final String? initialName; // NEW: Accept pre-filled name
  const AddCustomerView({super.key, this.initialName});

  @override
  State<AddCustomerView> createState() => _AddCustomerViewState();
}

class _AddCustomerViewState extends State<AddCustomerView> {
  late TextEditingController _nameCtrl;
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill name if passed
    _nameCtrl = TextEditingController(text: widget.initialName ?? "");
  }

  void _save() async {
    if (_nameCtrl.text.isNotEmpty) {
      final newCustomer = CustomerModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
      );
      
      await DataRepository().addCustomer(newCustomer);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer Added!")));
        // CRITICAL FIX: Return the new customer object
        Navigator.pop(context, newCustomer); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Customer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Shop/Customer Name")),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: "Address")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text("SAVE CUSTOMER"),
            ),
          ],
        ),
      ),
    );
  }
}