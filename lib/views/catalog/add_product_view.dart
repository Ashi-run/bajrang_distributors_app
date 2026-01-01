import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/data_repository.dart';

class AddProductView extends StatefulWidget {
  final String? initialGroup;
  final String? initialCategory;
  const AddProductView({super.key, this.initialGroup, this.initialCategory});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final _nameCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _price2Ctrl = TextEditingController();
  final _uomCtrl = TextEditingController(text: "Pkt");
  final _secUomCtrl = TextEditingController();
  final _factorCtrl = TextEditingController();
  String _imagePath = "";

  @override
  void initState() {
    super.initState();
    if(widget.initialGroup != null) _groupCtrl.text = widget.initialGroup!;
    if(widget.initialCategory != null) _catCtrl.text = widget.initialCategory!;
  }

  void _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imagePath = image.path);
  }

  void _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;

    final repo = DataRepository();

    // --- NEW: DUPLICATE CHECK ---
    // This stops the save if Name + Group + Category combination already exists
    if (repo.checkProductExists(_nameCtrl.text, _groupCtrl.text, _catCtrl.text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product already exists in this Group/Category!"), backgroundColor: Colors.red)
        );
      }
      return; // Stop execution here
    }

    final newProduct = ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      group: _groupCtrl.text,
      category: _catCtrl.text,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      price2: double.tryParse(_price2Ctrl.text),
      uom: _uomCtrl.text,
      secondaryUom: _secUomCtrl.text,
      conversionFactor: double.tryParse(_factorCtrl.text),
      image: _imagePath,
    );

    await repo.addProduct(newProduct);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Added Successfully!"))
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100, width: 100,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey)),
                child: _imagePath.isEmpty ? const Icon(Icons.add_a_photo, color: Colors.grey) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_imagePath), fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _groupCtrl, decoration: const InputDecoration(labelText: "Group (Optional)", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _catCtrl, decoration: const InputDecoration(labelText: "Category (Optional)", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price 1 (Base)", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _uomCtrl, decoration: const InputDecoration(labelText: "Unit 1 (e.g. Pkt)", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            const Divider(),
            const Text("Secondary Unit (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _price2Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price 2", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _secUomCtrl, decoration: const InputDecoration(labelText: "Unit 2 (e.g. Box)", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: _factorCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Conversion Factor (1 Unit2 = ? Unit1)", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text("SAVE PRODUCT"),
            ),
          ],
        ),
      ),
    );
  }
}