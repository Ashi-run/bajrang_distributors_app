import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/data_repository.dart';

class EditProductView extends StatefulWidget {
  final ProductModel product;
  const EditProductView({super.key, required this.product});

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _groupCtrl;
  late TextEditingController _catCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _price2Ctrl;
  late TextEditingController _uomCtrl;
  late TextEditingController _secUomCtrl;
  late TextEditingController _factorCtrl;
  String _imagePath = "";

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _groupCtrl = TextEditingController(text: widget.product.group);
    _catCtrl = TextEditingController(text: widget.product.category);
    _priceCtrl = TextEditingController(text: widget.product.price.toString());
    _price2Ctrl = TextEditingController(text: widget.product.price2?.toString() ?? "");
    _uomCtrl = TextEditingController(text: widget.product.uom);
    _secUomCtrl = TextEditingController(text: widget.product.secondaryUom ?? "");
    _factorCtrl = TextEditingController(text: widget.product.conversionFactor?.toString() ?? "");
    _imagePath = widget.product.image;
  }

  void _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imagePath = image.path);
  }

  void _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;

    final updatedProduct = ProductModel(
      id: widget.product.id,
      name: _nameCtrl.text,
      // REMOVED VARIANT HERE
      group: _groupCtrl.text,
      category: _catCtrl.text,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      price2: double.tryParse(_price2Ctrl.text),
      uom: _uomCtrl.text,
      secondaryUom: _secUomCtrl.text,
      conversionFactor: double.tryParse(_factorCtrl.text),
      image: _imagePath,
    );

    await DataRepository().updateProduct(updatedProduct);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100, width: 100,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey)),
                child: _imagePath.isEmpty ? const Icon(Icons.add_a_photo, color: Colors.grey) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_imagePath), fit: BoxFit.cover, errorBuilder: (c,o,s)=>const Icon(Icons.image))),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _groupCtrl, decoration: const InputDecoration(labelText: "Group", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _catCtrl, decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price 1", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _uomCtrl, decoration: const InputDecoration(labelText: "Unit 1", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _price2Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price 2", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _secUomCtrl, decoration: const InputDecoration(labelText: "Unit 2", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: _factorCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Conversion Factor", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("UPDATE PRODUCT"),
            ),
          ],
        ),
      ),
    );
  }
}