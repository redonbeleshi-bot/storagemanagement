import 'package:flutter/material.dart';
import '../services/stock_services.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _stockService = StockService();
  late Future<List<Product>> _lowStockFuture;
  List<Product> _allProductsCache = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _lowStockFuture = _stockService.fetchLowStockProducts();
    });
    // ngarko edhe listën e plotë në sfond, e nevojshme për dropdown-in e Daljes
    _stockService.fetchAllProducts().then((products) {
      if (mounted) {
        setState(() => _allProductsCache = products);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok i Ulët'),
      ),
      drawer: AppDrawer(
        stockService: _stockService,
        allProducts: _allProductsCache,
        onDataChanged: _loadData,
      ),
      body: FutureBuilder<List<Product>>(
        future: _lowStockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Gabim: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Asnjë produkt nuk është me stok të ulët. Gjithçka në rregull!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  color: Colors.red[50],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.category ?? "Pa kategori"} • Min: ${product.minStockThreshold} ${product.unit}',
                    ),
                    trailing: Text(
                      '${product.stockQuantity} ${product.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // ✅ BUTONI I RI PËR RAPORTE - NË FUND TË MAJTË
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/raporte');
        },
        icon: const Icon(Icons.assessment),
        label: const Text('Raporte'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}