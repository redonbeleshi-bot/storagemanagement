import 'package:flutter/material.dart';
import '../services/stock_services.dart';

class OrderCartScreen extends StatefulWidget {
  final List<OrderItem> cartItems;
  final VoidCallback onOrderSubmitted;

  const OrderCartScreen({
    super.key,
    required this.cartItems,
    required this.onOrderSubmitted,
  });

  @override
  State<OrderCartScreen> createState() => _OrderCartScreenState();
}

class _OrderCartScreenState extends State<OrderCartScreen> {
  final _stockService = StockService();
  bool _isSubmitting = false;
  List<Supplier> _suppliers = [];
  bool _isLoadingSuppliers = true;

  // ✅ Grupi i produkteve sipas furnizuesit
  Map<String, List<OrderItem>> _groupedItems = {};

  @override
  void initState() {
    super.initState();
    _loadSuppliersAndGroupItems();
  }

  @override
  void didUpdateWidget(OrderCartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Nëse ndryshon lista e artikujve, rigrupo
    if (oldWidget.cartItems != widget.cartItems) {
      _groupItemsBySupplier();
    }
  }

  Future<void> _loadSuppliersAndGroupItems() async {
    setState(() {
      _isLoadingSuppliers = true;
    });

    try {
      // ✅ Ngarko furnizuesit
      _suppliers = await _stockService.fetchAllSuppliers();
      
      // ✅ Pastaj grupo produktet
      _groupItemsBySupplier();
      
    } catch (e) {
      // Nëse ka gabim, grupo pa furnizues
      _groupItemsBySupplier();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuppliers = false;
        });
      }
    }
  }

  // ✅ Grupimi i produkteve sipas furnizuesit
  void _groupItemsBySupplier() {
    _groupedItems = {};

    if (widget.cartItems.isEmpty) {
      return;
    }

    for (var item in widget.cartItems) {
      String? supplierName = _getSupplierForProduct(item.category);
      
      // Nëse nuk gjendet furnizues, përdor "Furnizues i panjohur"
      supplierName ??= 'Furnizues i panjohur';
      
      if (!_groupedItems.containsKey(supplierName)) {
        _groupedItems[supplierName] = [];
      }
      _groupedItems[supplierName]!.add(item);
    }
  }

  // ✅ Merr furnizuesin për një produkt bazuar në kategorinë e tij
  String? _getSupplierForProduct(String category) {
    for (var supplier in _suppliers) {
      if (supplier.categories.contains(category)) {
        return supplier.name;
      }
    }
    return null;
  }

  // ✅ Merr ikonën për kategorinë
  IconData _getCategoryIcon(String category) {
    final icons = {
      'Tekstile': Icons.style,
      'Pastrim': Icons.cleaning_services,
      'Ushqim & Pije': Icons.restaurant,
      'Kozmetikë': Icons.spa,
    };
    return icons[category] ?? Icons.category;
  }

  // ✅ Merr ngjyrën për kategorinë
  Color _getCategoryColor(String category) {
    final colors = {
      'Tekstile': Colors.blue,
      'Pastrim': Colors.green,
      'Ushqim & Pije': Colors.orange,
      'Kozmetikë': Colors.pink,
    };
    return colors[category] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Shporta e Porosive'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (widget.cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _clearCart,
              tooltip: 'Pastro shportën',
            ),
        ],
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Shporta është bosh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shto produkte nga lista e furnizuesve',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kthehu te Furnizuesit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _isLoadingSuppliers
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // ✅ Përmbledhja e shportës
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        border: Border(
                          bottom: BorderSide(color: Colors.indigo[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${widget.cartItems.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const Text(
                                'Artikuj',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.indigo[200],
                          ),
                          Column(
                            children: [
                              Text(
                                '${_groupedItems.keys.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const Text(
                                'Furnizues',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ✅ Lista e produkteve të grupuara sipas furnizuesit
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _groupedItems.keys.length,
                        itemBuilder: (context, supplierIndex) {
                          final supplierName = _groupedItems.keys.elementAt(supplierIndex);
                          final items = _groupedItems[supplierName]!;

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ Header-i i furnizuesit
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo[50],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.business,
                                          color: Colors.indigo,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              supplierName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                            Text(
                                              '${items.length} produkte',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // ✅ Butoni për të hequr të gjitha produktet e këtij furnizuesi
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _removeSupplierItems(supplierName);
                                        },
                                        tooltip: 'Hiq të gjitha produktet e këtij furnizuesi',
                                      ),
                                    ],
                                  ),
                                ),

                                // ✅ Lista e produkteve të këtij furnizuesi
                                ...items.map((item) {
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(item.category).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(item.category),
                                        color: _getCategoryColor(item.category),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item.productName,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      '${item.category} • ${item.unit}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${item.quantity} ${item.unit}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            _removeItemFromSupplier(supplierName, item);
                                          },
                                          tooltip: 'Hiq nga shporta',
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Pjesa e poshtme - Totali dhe butonat
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        border: Border(
                          top: BorderSide(color: Colors.indigo[200]!),
                        ),
                      ),
                      child: Column(
                        children: [
                          // ✅ Përmbledhja e kategorive
                          _buildCategorySummary(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Totali i produkteve:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.cartItems.length} artikuj',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _submitOrder,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: Text(
                                    _isSubmitting ? 'Duke porositur...' : '✅ Porositur',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _clearCart,
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Anulo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ✅ Heq të gjitha produktet e një furnizuesi
  void _removeSupplierItems(String supplierName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('⚠️ Hiq produktet e $supplierName'),
          content: Text(
            'A jeni i sigurt që doni të hiqni të gjitha produktet e $supplierName nga shporta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anulo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  // Fshi të gjitha produktet e këtij furnizuesi
                  widget.cartItems.removeWhere((item) {
                    final supplier = _getSupplierForProduct(item.category);
                    return supplier == supplierName;
                  });
                  _groupItemsBySupplier();
                });
                // Nëse shporta u bë bosh, kthehu
                if (widget.cartItems.isEmpty) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hiq'),
            ),
          ],
        );
      },
    );
  }

  // ✅ Heq një produkt specifik nga një furnizues
  void _removeItemFromSupplier(String supplierName, OrderItem itemToRemove) {
    setState(() {
      widget.cartItems.removeWhere((item) => 
        item.productName == itemToRemove.productName &&
        item.category == itemToRemove.category
      );
      _groupItemsBySupplier();
    });
    // Nëse shporta u bë bosh, kthehu
    if (widget.cartItems.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  // Përmbledhja e kategorive
  Widget _buildCategorySummary() {
    if (widget.cartItems.isEmpty) return const SizedBox.shrink();

    final Map<String, List<OrderItem>> groupedByCategory = {};
    for (var item in widget.cartItems) {
      if (!groupedByCategory.containsKey(item.category)) {
        groupedByCategory[item.category] = [];
      }
      groupedByCategory[item.category]!.add(item);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: groupedByCategory.entries.map((entry) {
        final totalItems = entry.value.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(entry.key).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getCategoryColor(entry.key),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(entry.key),
                size: 14,
                color: _getCategoryColor(entry.key),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.key}: $totalItems',
                style: TextStyle(
                  fontSize: 12,
                  color: _getCategoryColor(entry.key),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _clearCart() {
    if (widget.cartItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('⚠️ Pastro Shportën'),
          content: const Text(
            'A jeni i sigurt që doni të pastroni të gjitha produktet nga shporta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anulo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  widget.cartItems.clear();
                  _groupItemsBySupplier();
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pastro'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (widget.cartItems.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      for (var item in widget.cartItems) {
        await _stockService.addPurchaseRequest(
          productName: item.productName,
          quantity: item.quantity,
          category: item.category,
          unit: item.unit,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${widget.cartItems.length} porosi u krijuan me sukses!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      widget.cartItems.clear();
      widget.onOrderSubmitted();

      if (!mounted) return;
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gabim gjatë porositjes: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}