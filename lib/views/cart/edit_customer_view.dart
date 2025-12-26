import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/data_repository.dart';

class EditCustomerView extends StatefulWidget {
  final CustomerModel customer;
  const EditCustomerView({super.key, required this.customer});

  @override
  State<EditCustomerView> createState() => _EditCustomerViewState();
}

class _EditCustomerViewState extends State<EditCustomerView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _phoneCtrl = TextEditingController(text: widget.customer.phone);
    _addressCtrl = TextEditingController(text: widget.customer.address);
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final updated = CustomerModel(
        id: widget.customer.id,
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
      );

      await DataRepository().updateCustomer(updated);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer Updated")));
        Navigator.pop(context, true); // Return true to refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Customer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name"), validator: (v) => v!.isEmpty ? "Required" : null),
              TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
              TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: "Address")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text("SAVE CHANGES"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}