import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/stock_services.dart';
import 'stock_dialogs.dart';

/// Hamburger menu i përbashkët, përdoret në të gjitha ekranet kryesore.
/// onDataChanged thirret pas çdo veprimi (hyrje/dalje/porosi) që e ndryshon
/// të dhënat, që ekrani aktual të mund të rifreskohet.
class AppDrawer extends StatelessWidget {
  final StockService stockService;
  final List<Product> allProducts;
  final VoidCallback onDataChanged;

  const AppDrawer({
    super.key,
    required this.stockService,
    required this.allProducts,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menaxhim Magazine',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.warehouse_outlined),
              title: const Text('Magazina'),
              onTap: () {
                Navigator.of(context).pop(); // mbyll drawer-in
                Navigator.of(context).pushNamed('/magazina');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Hyrje'),
              onTap: () async {
                Navigator.of(context).pop();
                await showHyrjeDialog(
                  context: context,
                  stockService: stockService,
                  onSuccess: onDataChanged,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.outbox_outlined),
              title: const Text('Dalje'),
              onTap: () async {
                Navigator.of(context).pop();
                await showDaljeDialog(
                  context: context,
                  stockService: stockService,
                  products: allProducts,
                  onSuccess: onDataChanged,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Furnizuesit'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/furnizuesit');
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Dil', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}