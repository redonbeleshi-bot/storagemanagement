import 'dart:io';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

class ExportService {
  /// Eksporto të dhënat në Excel dhe shkarko
  static Future<void> exportToExcel({
    required List<Map<String, dynamic>> data,
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    try {
      // Krijo Excel file
      final excel = Excel.createExcel();
      
      // Krijo sheet-in
      final sheet = excel['Raporti'];
      
      // Shto titujt
      _addHeaders(sheet, reportType);
      
      // Shto të dhënat
      _addData(sheet, data, reportType);
      
      // Shto informacionin e raportit në fund
      _addFooter(sheet, reportType, startDate, endDate);
      
      // Merr të dhënat e Excel-it
      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception('Nuk mund të krijohet Excel file');
      }
      
      final fileName = 'raporti_${reportType}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      if (kIsWeb) {
        // ✅ PËR WEB: Shkarko direkt nga browser-i
        _downloadFileWeb(excelBytes, fileName);
      } else {
        // ✅ PËR MOBILE/DESKTOP: Përdor path_provider dhe share
        await _downloadFileMobile(excelBytes, fileName);
      }
      
    } catch (e) {
      throw Exception('Gabim gjatë eksportimit: $e');
    }
  }
  
  /// Shkarko për Web (Chrome, Edge, etj.)
  static void _downloadFileWeb(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Krijo një element anchor për shkarkim
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    
    // Shto në dokument, kliko dhe fshi
    final body = html.document.body;
    if (body != null) {
      body.children.add(anchor);
      anchor.click();
      body.children.remove(anchor);
    }
    
    // Pastro URL-në
    html.Url.revokeObjectUrl(url);
  }
  
  /// Shkarko për Mobile/Desktop (përdor share_plus)
  static Future<void> _downloadFileMobile(List<int> bytes, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      // Shpërndaje file-in
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Raporti i eksportuar',
      );
    } catch (e) {
      throw Exception('Gabim gjatë shkarkimit: $e');
    }
  }
  
  static void _addHeaders(Sheet sheet, String reportType) {
    final headers = _getHeaders(reportType);
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }
  }
  
  static List<String> _getHeaders(String reportType) {
    switch (reportType) {
      case 'hyrje':
        return ['#', 'Produkti', 'Sasia', 'Data', 'Koha'];
      case 'dalje':
        return ['#', 'Produkti', 'Sasia', 'Destinacioni', 'Data', 'Koha'];
      case 'porosi':
        return ['#', 'Produkti', 'Sasia', 'Kategoria', 'Njësia', 'Statusi', 'Data', 'Koha'];
      default:
        return ['#', 'Produkti', 'Sasia', 'Data', 'Koha'];
    }
  }
  
  static void _addData(Sheet sheet, List<Map<String, dynamic>> data, String reportType) {
    int rowIndex = 1;
    int num = 1;
    
    for (var item in data) {
      final date = DateTime.parse(item['created_at']);
      final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      
      switch (reportType) {
        case 'hyrje':
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = IntCellValue(num);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(item['product_name'] ?? '-');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = IntCellValue(item['quantity']?.toInt() ?? 0);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(dateStr);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(timeStr);
          break;
          
        case 'dalje':
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = IntCellValue(num);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(item['product_name'] ?? '-');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = IntCellValue(item['quantity']?.toInt() ?? 0);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(item['destination'] ?? '-');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(dateStr);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(timeStr);
          break;
          
        case 'porosi':
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = IntCellValue(num);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(item['product_name'] ?? '-');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = IntCellValue(item['quantity']?.toInt() ?? 0);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(item['category'] ?? '-');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(item['unit'] ?? '-');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(item['status'] ?? '-');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(dateStr);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(timeStr);
          break;
      }
      
      rowIndex++;
      num++;
    }
  }
  
  static void _addFooter(Sheet sheet, String reportType, String startDate, String endDate) {
    int rowIndex = sheet.maxRows;
    
    // Shto rresht bosh
    rowIndex++;
    
    // Totali i të dhënave
    final totalRows = sheet.maxRows - 2; // minus header dhe rreshtin bosh
    final cell1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    cell1.value = TextCellValue('Totali:');
    cell1.cellStyle = CellStyle(bold: true);
    
    final cell2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
    cell2.value = IntCellValue(totalRows);
    
    rowIndex++;
    
    // Periudha
    final cell3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    cell3.value = TextCellValue('Periudha:');
    cell3.cellStyle = CellStyle(bold: true);
    
    final cell4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
    cell4.value = TextCellValue('$startDate - $endDate');
    
    rowIndex++;
    
    // Data e gjenerimit
    final now = DateTime.now();
    final nowStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final cell5 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    cell5.value = TextCellValue('Gjeneruar më:');
    cell5.cellStyle = CellStyle(bold: true);
    
    final cell6 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
    cell6.value = TextCellValue(nowStr);
    
    // Autofit columns
    for (int i = 0; i < 8; i++) {
      sheet.setColumnWidth(i, 20);
    }
  }
}