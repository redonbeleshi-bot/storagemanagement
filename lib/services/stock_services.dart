import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MODELET
// ============================================================

class Product {
  final String id;
  final String name;
  final String? category;
  final String unit;
  final num stockQuantity;
  final num minStockThreshold;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.stockQuantity,
    required this.minStockThreshold,
  });

  bool get isLowStock => stockQuantity <= minStockThreshold;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      unit: map['unit'] as String,
      stockQuantity: map['stock_quantity'] as num,
      minStockThreshold: map['min_stock_threshold'] as num,
    );
  }
}

class Supplier {
  final String id;
  final String name;
  final String? contactPhone;
  final String? contactEmail;
  final List<String> categories;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.contactPhone,
    this.contactEmail,
    required this.categories,
    required this.createdAt,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      contactPhone: map['contact_phone'] as String?,
      contactEmail: map['contact_email'] as String?,
      categories: map['categories'] != null 
          ? List<String>.from(map['categories'] as List)
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'categories': categories,
    };
  }
}

// ✅ KLASA E RE: OrderItem (për artikujt në shportë)
class OrderItem {
  final String productName;
  final num quantity;
  final String category;
  final String unit;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.category,
    required this.unit,
  });
}

// ============================================================
// KONSTANTET
// ============================================================

const List<String> kProductCategories = [
  'Tekstile',
  'Pastrim',
  'Ushqim & Pije',
  'Kozmetikë',
];

const List<String> kProductUnits = ['copë', 'litër'];

const Map<String, String> kDestinations = {
  'bar': 'Magazina e barit',
  'restorant': 'Magazina e restorantit',
  'hotel': 'Magazina e hotelit',
};

// ============================================================
// STOCK SERVICE
// ============================================================

class StockService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Merr të gjitha produktet
  Future<List<Product>> fetchAllProducts() async {
    final data = await _supabase
        .from('products')
        .select()
        .order('name', ascending: true);

    return (data as List)
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Merr produktet me stok të ulët
  Future<List<Product>> fetchLowStockProducts() async {
    final all = await fetchAllProducts();
    return all.where((p) => p.isLowStock).toList();
  }

  /// HYRJE: shton stok
  Future<void> addIncomingStock({
    required String name,
    required num quantity,
    required String category,
    required String unit,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final existing = await _supabase
        .from('products')
        .select('id, stock_quantity')
        .ilike('name', name.trim())
        .maybeSingle();

    String productId;

    if (existing != null) {
      productId = existing['id'] as String;
      final currentQuantity = existing['stock_quantity'] as num;

      await _supabase
          .from('products')
          .update({'stock_quantity': currentQuantity + quantity})
          .eq('id', productId);
    } else {
      final inserted = await _supabase
          .from('products')
          .insert({
            'name': name.trim(),
            'category': category,
            'unit': unit,
            'stock_quantity': quantity,
            'min_stock_threshold': 10,
          })
          .select('id')
          .single();

      productId = inserted['id'] as String;
    }

    await _supabase.from('stock_movements').insert({
      'product_id': productId,
      'movement_type': 'hyrje',
      'quantity': quantity,
      'moved_by': userId,
    });
  }

  /// DALJE: nxjerr stok
  Future<void> addOutgoingStock({
    required String productId,
    required num quantity,
    required String destination,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final product = await _supabase
        .from('products')
        .select('stock_quantity')
        .eq('id', productId)
        .single();

    final currentQuantity = product['stock_quantity'] as num;

    if (quantity > currentQuantity) {
      throw Exception('Sasia e daljes tejkalon stokun aktual');
    }

    await _supabase.from('stock_movements').insert({
      'product_id': productId,
      'movement_type': 'dalje',
      'quantity': quantity,
      'moved_by': userId,
      'destination': destination,
    });

    await _supabase
        .from('products')
        .update({'stock_quantity': currentQuantity - quantity})
        .eq('id', productId);
  }

  /// POROSI: krijon kërkesë porosie
  Future<void> addPurchaseRequest({
    required String productName,
    required num quantity,
    required String category,
    required String unit,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from('purchase_requests').insert({
      'product_name': productName.trim(),
      'quantity': quantity,
      'category': category,
      'unit': unit,
      'requested_by': userId,
    });
  }

  // ============================================================
  // METODAT PËR FURNIZUESIT
  // ============================================================

  /// Merr të gjithë furnizuesit
  Future<List<Supplier>> fetchAllSuppliers() async {
    final data = await _supabase
        .from('suppliers')
        .select('*')
        .order('name', ascending: true);

    return (data as List)
        .map((item) => Supplier.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Merr një furnizues sipas ID-së
  Future<Supplier?> fetchSupplierById(String id) async {
    final data = await _supabase
        .from('suppliers')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Supplier.fromMap(data as Map<String, dynamic>);
  }

  /// Krijo një furnizues të ri
  Future<void> addSupplier({
    required String name,
    String? contactPhone,
    String? contactEmail,
    required List<String> categories,
  }) async {
    await _supabase.from('suppliers').insert({
      'name': name.trim(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'categories': categories,
    });
  }

  /// Përditëso një furnizues
  Future<void> updateSupplier({
    required String id,
    required String name,
    String? contactPhone,
    String? contactEmail,
    required List<String> categories,
  }) async {
    await _supabase
        .from('suppliers')
        .update({
          'name': name.trim(),
          'contact_phone': contactPhone,
          'contact_email': contactEmail,
          'categories': categories,
        })
        .eq('id', id);
  }

  /// Fshi një furnizues
  Future<void> deleteSupplier(String id) async {
    await _supabase.from('suppliers').delete().eq('id', id);
  }
}