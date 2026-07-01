import 'package:flutter/material.dart';
import '../services/stock_services.dart';

/// Dialog për HYRJE stoku: shto produkt të ri ose rrit stokun e një produkti ekzistues
Future<void> showHyrjeDialog({
  required BuildContext context,
  required StockService stockService,
  required VoidCallback onSuccess,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  String? selectedCategory;
  String? selectedUnit;
  String? errorText;
  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hyrje - Shto Produkt'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Emri i produktit',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Shkruaj emrin e produktit'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Sasia',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final n = num.tryParse((value ?? '').replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Vendos një sasi të vlefshme';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Lloji / Kategoria',
                        border: OutlineInputBorder(),
                      ),
                      items: kProductCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedCategory = value),
                      validator: (value) => value == null ? 'Zgjidh kategorinë' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Njësia (copë / litër)',
                        border: OutlineInputBorder(),
                      ),
                      items: kProductUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedUnit = value),
                      validator: (value) => value == null ? 'Zgjidh njësinë' : null,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anulo'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setDialogState(() => isSaving = true);

                        try {
                          await stockService.addIncomingStock(
                            name: nameController.text,
                            quantity: num.parse(
                              quantityController.text.replaceAll(',', '.'),
                            ),
                            category: selectedCategory!,
                            unit: selectedUnit!,
                          );

                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          onSuccess();
                        } catch (e) {
                          setDialogState(() {
                            errorText = 'Gabim: $e';
                            isSaving = false;
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ruaj'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Dialog për DALJE stoku: nxjerr stok drejt bar/restorant/hotel
Future<void> showDaljeDialog({
  required BuildContext context,
  required StockService stockService,
  required List<Product> products,
  required VoidCallback onSuccess,
}) async {
  final formKey = GlobalKey<FormState>();
  final quantityController = TextEditingController();
  Product? selectedProduct;
  String? selectedDestination;
  String? errorText;
  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Dalje - Transfero Stok'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Product>(
                      value: selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Produkti',
                        border: OutlineInputBorder(),
                      ),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.name} (${p.stockQuantity} ${p.unit})'),
                              ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedProduct = value),
                      validator: (value) => value == null ? 'Zgjidh produktin' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDestination,
                      decoration: const InputDecoration(
                        labelText: 'Destinacioni',
                        border: OutlineInputBorder(),
                      ),
                      items: kDestinations.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedDestination = value),
                      validator: (value) => value == null ? 'Zgjidh destinacionin' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Sasia',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final n = num.tryParse((value ?? '').replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Vendos një sasi të vlefshme';
                        return null;
                      },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anulo'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setDialogState(() => isSaving = true);

                        try {
                          await stockService.addOutgoingStock(
                            productId: selectedProduct!.id,
                            quantity: num.parse(
                              quantityController.text.replaceAll(',', '.'),
                            ),
                            destination: selectedDestination!,
                          );

                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          onSuccess();
                        } catch (e) {
                          setDialogState(() {
                            errorText = 'Gabim: $e';
                            isSaving = false;
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ruaj'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Dialog për porosi te furnizuesi
Future<void> showPurchaseRequestDialog({
  required BuildContext context,
  required StockService stockService,
  required VoidCallback onSuccess,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  String? selectedCategory;
  String? selectedUnit;
  String? errorText;
  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Porosit Produkte'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Emri i produktit',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Shkruaj emrin e produktit'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Sasia',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final n = num.tryParse((value ?? '').replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Vendos një sasi të vlefshme';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Lloji / Kategoria',
                        border: OutlineInputBorder(),
                      ),
                      items: kProductCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedCategory = value),
                      validator: (value) => value == null ? 'Zgjidh kategorinë' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Njësia (copë / litër)',
                        border: OutlineInputBorder(),
                      ),
                      items: kProductUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedUnit = value),
                      validator: (value) => value == null ? 'Zgjidh njësinë' : null,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anulo'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setDialogState(() => isSaving = true);

                        try {
                          await stockService.addPurchaseRequest(
                            productName: nameController.text,
                            quantity: num.parse(
                              quantityController.text.replaceAll(',', '.'),
                            ),
                            category: selectedCategory!,
                            unit: selectedUnit!,
                          );

                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          onSuccess();
                        } catch (e) {
                          setDialogState(() {
                            errorText = 'Gabim: $e';
                            isSaving = false;
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ruaj'),
              ),
            ],
          );
        },
      );
    },
  );
}