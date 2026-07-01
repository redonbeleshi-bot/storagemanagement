import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/stock_services.dart';
import '../widgets/app_drawer.dart';
import '../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _stockService = StockService();
  final _supabase = Supabase.instance.client;
  
  String _selectedReportType = 'hyrje';
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCustomRange = '1_jave';
  
  List<Map<String, dynamic>> _reportData = [];
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;

  final List<String> _reportTypes = ['hyrje', 'dalje', 'porosi'];
  final Map<String, String> _reportLabels = {
    'hyrje': '📥 Hyrje Stoku',
    'dalje': '📤 Dalje Stoku',
    'porosi': '🛒 Porosi te Furnizuesit',
  };
  final Map<String, String> _customRanges = {
    '1_jave': '7 ditët e fundit',
    '1_muaj': '30 ditët e fundit',
    'custom': '📅 Përcakto datat',
  };

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
    _loadReportData();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    switch (_selectedCustomRange) {
      case '1_jave':
        _startDate = DateTime(now.year, now.month, now.day - 7);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case '1_muaj':
        _startDate = DateTime(now.year, now.month - 1, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      default:
        _startDate = DateTime(now.year, now.month, now.day - 7);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  Future<void> _loadReportData() async {
    if (_startDate == null || _endDate == null) {
      print('❌ Datat janë null!');
      return;
    }

    print('📅 Periudha: $_startDate - $_endDate');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> data = [];

      switch (_selectedReportType) {
        case 'hyrje':
          data = await _fetchStockMovements('hyrje');
          break;
        case 'dalje':
          data = await _fetchStockMovements('dalje');
          break;
        case 'porosi':
          data = await _fetchPurchaseRequests();
          break;
      }

      print('📊 U gjetën ${data.length} regjistrime');

      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Gabim: $e');
      setState(() {
        _errorMessage = 'Gabim gjatë ngarkimit të raportit: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStockMovements(String type) async {
    try {
      // ✅ PËRDOR VETËM DATËN (pa kohën)
      final startDateStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      final endDateStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      
      print('🔍 Kërko lëvizje të tipit "$type" nga $startDateStr deri $endDateStr');

      final response = await _supabase
          .from('stock_movements')
          .select('''
            *,
            products!inner(name)
          ''')
          .eq('movement_type', type)
          .gte('created_at', '$startDateStr 00:00:00')
          .lte('created_at', '$endDateStr 23:59:59')
          .order('created_at', ascending: false);

      print('📦 U gjetën ${(response as List).length} lëvizje');

      return (response as List<dynamic>).map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'id': map['id'],
          'product_name': map['products']['name'],
          'quantity': map['quantity'],
          'destination': map['destination'] ?? '-',
          'created_at': map['created_at'],
          'movement_type': map['movement_type'],
        };
      }).toList();
    } catch (e) {
      print('❌ Gabim në fetchStockMovements: $e');
      // Nëse tabela products nuk ka lidhje, provo pa të
      try {
        final startDateStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
        final endDateStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
        
        final response = await _supabase
            .from('stock_movements')
            .select('*')
            .eq('movement_type', type)
            .gte('created_at', '$startDateStr 00:00:00')
            .lte('created_at', '$endDateStr 23:59:59')
            .order('created_at', ascending: false);

        print('📦 U gjetën ${(response as List).length} lëvizje (pa join)');

        return (response as List<dynamic>).map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'id': map['id'],
            'product_name': map['product_name'] ?? 'Produkt i panjohur',
            'quantity': map['quantity'],
            'destination': map['destination'] ?? '-',
            'created_at': map['created_at'],
            'movement_type': map['movement_type'],
          };
        }).toList();
      } catch (e2) {
        print('❌ Gabim i dytë: $e2');
        rethrow;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPurchaseRequests() async {
    try {
      final startDateStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      final endDateStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      
      print('🔍 Kërko porosi nga $startDateStr deri $endDateStr');

      final response = await _supabase
          .from('purchase_requests')
          .select('*')
          .gte('created_at', '$startDateStr 00:00:00')
          .lte('created_at', '$endDateStr 23:59:59')
          .order('created_at', ascending: false);

      print('📦 U gjetën ${(response as List).length} porosi');

      return (response as List<dynamic>).map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'id': map['id'],
          'product_name': map['product_name'],
          'quantity': map['quantity'],
          'category': map['category'] ?? '-',
          'unit': map['unit'] ?? 'copë',
          'status': map['status'] ?? 'pending',
          'created_at': map['created_at'],
        };
      }).toList();
    } catch (e) {
      print('❌ Gabim në fetchPurchaseRequests: $e');
      rethrow;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      // ✅ VENDOS DATAT NË MESNATË PËR TË MARRË TË GJITHA REGJISTRIMET
      final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      
      print('📅 Datat e zgjedhura: $start - $end');
      setState(() {
        _startDate = start;
        _endDate = end;
        _selectedCustomRange = 'custom';
      });
      _loadReportData();
    }
  }

  Future<void> _exportToExcel() async {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nuk ka të dhëna për të eksportuar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final startDateStr = '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}';
      final endDateStr = '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}';
      
      await ExportService.exportToExcel(
        data: _reportData,
        reportType: _selectedReportType,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Raporti u eksportua me sukses!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gabim gjatë eksportimit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Raporte'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isExporting 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download),
            onPressed: _isExporting ? null : _exportToExcel,
            tooltip: 'Eksporto në Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Rifresko',
          ),
        ],
      ),
      drawer: AppDrawer(
        stockService: _stockService,
        allProducts: [],
        onDataChanged: () {},
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(
            child: _isLoading
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
                            ],
                          ),
                        ),
                      )
                    : _reportData.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Nuk ka të dhëna për periudhën e zgjedhur.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildReportList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Type Dropdown
          Row(
            children: [
              const Text('Lloji: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedReportType,
                  isExpanded: true,
                  items: _reportTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_reportLabels[type]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedReportType = value;
                      });
                      _loadReportData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date Range Selection
          Row(
            children: [
              const Text('Periudha: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCustomRange,
                  isExpanded: true,
                  items: _customRanges.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCustomRange = value;
                        _setDefaultDates();
                      });
                      if (value == 'custom') {
                        _selectDateRange();
                      } else {
                        _loadReportData();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          
          // Show selected dates
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.indigo),
                  ),
                ],
              ),
            ),
          ],
          
          // Numri i të dhënave
          if (_reportData.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '📋 Gjithsej: ${_reportData.length} regjistrime',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _reportData.length,
      itemBuilder: (context, index) {
        final item = _reportData[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: _getLeadingIcon(item),
            title: Text(
              _getTitle(item),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(_getSubtitle(item)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getQuantityText(item),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getQuantityColor(item),
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(DateTime.parse(item['created_at'])),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getLeadingIcon(Map<String, dynamic> item) {
    if (_selectedReportType == 'porosi') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
      );
    }
    final isHyrje = item['movement_type'] == 'hyrje';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHyrje ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isHyrje ? Icons.arrow_downward : Icons.arrow_upward,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  String _getTitle(Map<String, dynamic> item) {
    return item['product_name'] ?? 'Produkt i panjohur';
  }

  String _getSubtitle(Map<String, dynamic> item) {
    if (_selectedReportType == 'porosi') {
      return 'Kategoria: ${item['category'] ?? '-'} • Statusi: ${_getStatusLabel(item['status'] ?? 'pending')}';
    }
    final destination = item['destination'] ?? '';
    if (destination.isNotEmpty && destination != '-') {
      return '📍 Destinacioni: ${_getDestinationLabel(destination)}';
    }
    return 'Lloji: ${item['movement_type'] ?? '-'}';
  }

  String _getStatusLabel(String status) {
    final labels = {
      'pending': '⏳ Në pritje',
      'ordered': '📦 Porositur',
      'received': '✅ Pranuar',
      'cancelled': '❌ Anuluar',
    };
    return labels[status] ?? status;
  }

  String _getDestinationLabel(String destination) {
    final labels = {
      'bar': '🍸 Bar',
      'restorant': '🍽️ Restorant',
      'hotel': '🏨 Hotel',
    };
    return labels[destination] ?? destination;
  }

  String _getQuantityText(Map<String, dynamic> item) {
    final qty = item['quantity']?.toString() ?? '0';
    if (_selectedReportType == 'porosi') {
      final unit = item['unit'] ?? 'copë';
      return '$qty $unit';
    }
    return '$qty copë';
  }

  Color _getQuantityColor(Map<String, dynamic> item) {
    if (_selectedReportType == 'porosi') {
      return Colors.orange;
    }
    final isHyrje = item['movement_type'] == 'hyrje';
    return isHyrje ? Colors.green : Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}