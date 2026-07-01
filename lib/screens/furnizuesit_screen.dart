import 'package:flutter/material.dart';
import '../services/stock_services.dart';
import '../widgets/app_drawer.dart';
import 'order_cart_screen.dart';

class FurnizuesitScreen extends StatefulWidget {
  const FurnizuesitScreen({super.key});

  @override
  State<FurnizuesitScreen> createState() => _FurnizuesitScreenState();
}

class _FurnizuesitScreenState extends State<FurnizuesitScreen> {
  final _stockService = StockService();
  List<Supplier> _suppliers = [];
  List<OrderItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Kategoritë e disponueshme
  final List<String> _allCategories = [
    'Tekstile',
    'Pastrim',
    'Ushqim & Pije',
    'Kozmetikë',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Tekstile': Icons.style,
    'Pastrim': Icons.cleaning_services,
    'Ushqim & Pije': Icons.restaurant,
    'Kozmetikë': Icons.spa,
  };

  final Map<String, Color> _categoryColors = {
    'Tekstile': Colors.blue,
    'Pastrim': Colors.green,
    'Ushqim & Pije': Colors.orange,
    'Kozmetikë': Colors.pink,
  };

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final suppliers = await _stockService.fetchAllSuppliers();
      setState(() {
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gabim gjatë ngarkimit të furnizuesve: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ Shto në shportë
  void _addToCart(OrderItem item) {
    setState(() {
      _cartItems.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "${item.productName}" u shtua në shportë!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ Shiko shportën - VERSIONI I KORRIGJUAR
  void _viewCart() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shporta është bosh! Shto produkte fillimisht.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderCartScreen(
          cartItems: _cartItems,
          onOrderSubmitted: () {
            setState(() {
              _cartItems.clear();
            });
          },
        ),
      ),
    );
  }

  Future<void> _showAddSupplierDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    List<String> selectedCategories = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('➕ Shto Furnizues të Ri'),
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
                          labelText: 'Emri i Furnizuesit',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) => 
                            value == null || value.trim().isEmpty 
                                ? 'Shkruaj emrin e furnizuesit' 
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefoni',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.contains('@')) {
                              return 'Email jo valid';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kategoritë që furnizon:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _allCategories.map((category) {
                          final isSelected = selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedCategories.add(category);
                                } else {
                                  selectedCategories.remove(category);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: _categoryColors[category]?.withOpacity(0.3),
                            checkmarkColor: _categoryColors[category],
                            avatar: Icon(
                              _categoryIcons[category],
                              size: 16,
                              color: isSelected ? _categoryColors[category] : Colors.grey,
                            ),
                          );
                        }).toList(),
                      ),
                      if (selectedCategories.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '⚠️ Zgjidh të paktën një kategori',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (selectedCategories.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Zgjidh të paktën një kategori'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    try {
                      await _stockService.addSupplier(
                        name: nameController.text,
                        contactPhone: phoneController.text.isNotEmpty 
                            ? phoneController.text 
                            : null,
                        contactEmail: emailController.text.isNotEmpty 
                            ? emailController.text 
                            : null,
                        categories: selectedCategories,
                      );
                      
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      _loadSuppliers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Furnizuesi u shtua me sukses!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Gabim: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ruaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showOrderDialog(Supplier supplier) async {
    // Së pari merr të gjitha produktet
    final products = await _stockService.fetchAllProducts();
    
    // Filtro produktet sipas kategorive që furnizon ky furnizues
    final availableProducts = products.where((p) {
      return p.category != null && supplier.categories.contains(p.category);
    }).toList();

    // Krijo një opsion "Produkt i Ri"
    final newProductOption = Product(
      id: 'new',
      name: '🆕 Produkt i Ri',
      category: null,
      unit: 'copë',
      stockQuantity: 0,
      minStockThreshold: 0,
    );

    // Lista e produkteve + opsioni "Produkt i Ri"
    final allOptions = [newProductOption, ...availableProducts];

    final formKey = GlobalKey<FormState>();
    Product? selectedProduct;
    final quantityController = TextEditingController();
    
    // Kontrolluesit për produktin e ri
    final newNameController = TextEditingController();
    String? newCategory;
    String? newUnit;

    bool isNewProduct = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('🛒 Shto në Shportë - ${supplier.name}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown për zgjedhjen e produktit
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(
                          labelText: 'Zgjidh Produktin',
                          border: OutlineInputBorder(),
                        ),
                        items: allOptions.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: p.id == 'new'
                                ? Row(
                                    children: const [
                                      Icon(Icons.add_circle, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text(
                                        '🆕 Produkt i Ri',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text('${p.name} (${p.stockQuantity} ${p.unit})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedProduct = value;
                            isNewProduct = value?.id == 'new';
                          });
                        },
                        validator: (value) => value == null ? 'Zgjidh një produkt' : null,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // === FUSHA PËR PRODUKTIN E RI ===
                      if (isNewProduct) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.new_label, color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '🆕 Produkt i Ri',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Emri i produktit
                              TextFormField(
                                controller: newNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Emri i Produktit',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.inventory_2_outlined),
                                ),
                                validator: (value) => 
                                    value == null || value.trim().isEmpty 
                                        ? 'Shkruaj emrin e produktit' 
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              
                              // Kategoria
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Kategoria',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                ),
                                items: _allCategories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _categoryIcons[cat] ?? Icons.category,
                                          size: 16,
                                          color: _categoryColors[cat],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(cat),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    newCategory = value;
                                  });
                                },
                                validator: (value) => value == null ? 'Zgjidh kategorinë' : null,
                              ),
                              const SizedBox(height: 12),
                              
                              // Njësia
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Njësia',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.scale),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'copë', child: Text('copë')),
                                  DropdownMenuItem(value: 'litër', child: Text('litër')),
                                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                                  DropdownMenuItem(value: 'paketë', child: Text('paketë')),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    newUnit = value;
                                  });
                                },
                                validator: (value) => value == null ? 'Zgjidh njësinë' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Sasia
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Sasia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final n = num.tryParse(value ?? '');
                          if (n == null || n <= 0) return 'Vendos një sasi të vlefshme';
                          return null;
                        },
                      ),

                      // ✅ TREGO NUMRIN E ARTIKUJVE NË SHPORTË
                      if (_cartItems.isNotEmpty) ...[
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart, color: Colors.indigo),
                              const SizedBox(width: 8),
                              Text(
                                '${_cartItems.length} artikuj në shportë',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                // ✅ Butoni për të parë shportën
                if (_cartItems.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _viewCart();
                    },
                    child: const Text('📋 Shiko Shportën'),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    try {
                      String productName;
                      String category;
                      String unit;
                      final quantity = num.parse(quantityController.text);

                      if (isNewProduct) {
                        productName = newNameController.text.trim();
                        category = newCategory!;
                        unit = newUnit!;
                      } else {
                        productName = selectedProduct!.name;
                        category = selectedProduct!.category ?? 'Pa kategori';
                        unit = selectedProduct!.unit;
                      }

                      // ✅ Shto në shportë
                      _addToCart(OrderItem(
                        productName: productName,
                        quantity: quantity,
                        category: category,
                        unit: unit,
                      ));

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Gabim: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('➕ Shto në Shportë'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 Furnizuesit'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Butoni për të parë shportën (me badge)
          if (_cartItems.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _viewCart,
                  tooltip: 'Shiko Shportën',
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
            tooltip: 'Rifresko',
          ),
        ],
      ),
      drawer: AppDrawer(
        stockService: _stockService,
        allProducts: [],
        onDataChanged: _loadSuppliers,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSuppliers,
                          child: const Text('Riprovo'),
                        ),
                      ],
                    ),
                  ),
                )
              : _suppliers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Nuk ka furnizues të regjistruar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddSupplierDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Shto Furnizues'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSuppliers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _suppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = _suppliers[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo[50],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.business,
                                          color: Colors.indigo,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              supplier.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (supplier.contactPhone != null)
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    supplier.contactPhone!,
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            if (supplier.contactEmail != null)
                                              Row(
                                                children: [
                                                  const Icon(Icons.email, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    supplier.contactEmail!,
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Butoni POROSIT
                                      ElevatedButton.icon(
                                        onPressed: () => _showOrderDialog(supplier),
                                        icon: const Icon(Icons.shopping_cart, size: 18),
                                        label: const Text('Porosit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Kategoritë që furnizon
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: supplier.categories.map((category) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _categoryColors[category]?.withOpacity(0.15) ?? Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _categoryColors[category] ?? Colors.grey,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _categoryIcons[category] ?? Icons.category,
                                              size: 14,
                                              color: _categoryColors[category] ?? Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _categoryColors[category] ?? Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      
      // ✅ BUTONAT NË FUND
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Butoni Raporte - Majtas
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).pushNamed('/raporte');
            },
            icon: const Icon(Icons.assessment),
            label: const Text('Raporte'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          // ✅ BUTONI SHTO FURNIZUES - Djathtas
          FloatingActionButton.extended(
            onPressed: _showAddSupplierDialog,
            icon: const Icon(Icons.add),
            label: const Text('Shto Furnizues'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}