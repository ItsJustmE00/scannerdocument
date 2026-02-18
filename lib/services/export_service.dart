import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:scannerdocument/models/scanned_document.dart';
import 'package:share_plus/share_plus.dart';

enum ExportFormat { json, csv, xlsx, txt, pdf }

class ExportService {
  Future<File> exportDocument(
    ScannedDocument document,
    ExportFormat format,
  ) async {
    final exportsDir = await _getExportsDir();
    final safeTitle = document.title
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toLowerCase();

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    late final String extension;
    String? content;
    Uint8List? bytes;

    switch (format) {
      case ExportFormat.json:
        extension = 'json';
        content = _buildJson(document);
      case ExportFormat.csv:
        extension = 'csv';
        content = _buildCsv(document);
      case ExportFormat.xlsx:
        extension = 'xlsx';
        bytes = _buildXlsx(document);
      case ExportFormat.txt:
        extension = 'txt';
        content = _buildTxt(document);
      case ExportFormat.pdf:
        extension = 'pdf';
        bytes = await _buildPdf(document);
    }

    final file = File(
      p.join(exportsDir.path, '${safeTitle}_$timestamp.$extension'),
    );

    if (bytes != null) {
      return file.writeAsBytes(bytes, flush: true);
    }

    return file.writeAsString(content ?? '', flush: true);
  }

  Future<void> shareExportedFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Export de document offline',
      ),
    );
  }

  String _buildJson(ScannedDocument document) {
    final payload = {
      'id': document.id,
      'title': document.title,
      'createdAt': document.createdAt.toIso8601String(),
      'imagePaths': document.imagePaths,
      'ocrText': document.ocrText,
      'extractedData': document.extractedData.toMap(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _buildCsv(ScannedDocument document) {
    final data = document.extractedData;
    final headers = [
      'id',
      'title',
      'created_at',
      'document_category',
      'document_domain',
      'invoice_number',
      'date',
      'amount',
      'currency',
      'email',
      'phone',
      'ocr_text',
    ];

    final values = [
      document.id,
      document.title,
      document.createdAt.toIso8601String(),
      data.documentCategory.label,
      data.documentDomain.label,
      data.invoiceNumber ?? '',
      data.date ?? '',
      data.amount ?? '',
      data.currency ?? '',
      data.email ?? '',
      data.phone ?? '',
      document.ocrText,
    ];

    final escapedValues = values.map(_escapeCsv).join(',');
    return '${headers.join(',')}\n$escapedValues\n';
  }

  String _buildTxt(ScannedDocument document) {
    final data = document.extractedData;
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(document.createdAt);
    final exportedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final lines = <String>[
      'SCANNER DOCUMENTS OFFLINE - RAPPORT D EXTRACTION',
      '==============================================================',
      'Genere le: $exportedAt',
      '',
      '[DOCUMENT]',
      _txtLine('Titre', document.title),
      _txtLine('Identifiant', document.id),
      _txtLine('Cree le', createdAt),
      _txtLine('Pages', '${document.imagePaths.length}'),
      '',
      '[CLASSIFICATION]',
      _txtLine('Type', data.documentCategory.label),
      _txtLine('Domaine', data.documentDomain.label),
      '',
      '[DONNEES EXTRAITES]',
      _txtLine('Numero facture', _normalizeValue(data.invoiceNumber)),
      _txtLine('Date', _normalizeValue(data.date)),
      _txtLine('Montant', _normalizeValue(data.amount)),
      _txtLine('Devise', _normalizeValue(data.currency)),
      _txtLine('Email', _normalizeValue(data.email)),
      _txtLine('Telephone', _normalizeValue(data.phone)),
      '',
      '[TEXTE SCANNE]',
      _truncate(
        document.ocrText.trim().isEmpty
            ? 'Texte vide.'
            : document.ocrText.trim(),
        12000,
      ),
      '',
      '--- Fin du rapport ---',
    ];
    return lines.join('\n');
  }

  Uint8List _buildXlsx(ScannedDocument document) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Resume') {
      excel.rename(defaultSheet, 'Resume');
    }

    final summarySheet = excel['Resume'];
    final dataSheet = excel['Donnees'];
    final ocrSheet = excel['Texte'];
    excel.setDefaultSheet('Resume');

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.teal,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final sectionStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('FF0D544D'),
      backgroundColorHex: ExcelColor.fromHexString('FFE4F3F1'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final keyStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FF233734'),
      backgroundColorHex: ExcelColor.fromHexString('FFF3F8F7'),
      verticalAlign: VerticalAlign.Center,
    );
    final valueStyle = CellStyle(
      textWrapping: TextWrapping.WrapText,
      verticalAlign: VerticalAlign.Top,
    );
    final ocrStyle = CellStyle(
      textWrapping: TextWrapping.WrapText,
      verticalAlign: VerticalAlign.Top,
      fontFamily: getFontFamily(FontFamily.Courier_New),
    );

    summarySheet.setColumnWidth(0, 22);
    summarySheet.setColumnWidth(1, 42);
    summarySheet.setColumnWidth(2, 18);
    summarySheet.setColumnWidth(3, 18);

    summarySheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('D1'),
    );
    summarySheet.updateCell(
      CellIndex.indexByString('A1'),
      TextCellValue('Rapport extraction - ${document.title}'),
      cellStyle: titleStyle,
    );
    summarySheet.setRowHeight(0, 28);

    var summaryRow = 2;
    _writeSectionHeader(
      summarySheet,
      summaryRow,
      'Informations document',
      sectionStyle,
    );
    summaryRow++;

    final metadata = <MapEntry<String, String>>[
      MapEntry('Identifiant', document.id),
      MapEntry(
        'Date creation',
        DateFormat('dd/MM/yyyy HH:mm').format(document.createdAt),
      ),
      MapEntry('Pages', '${document.imagePaths.length}'),
      MapEntry('Type', document.extractedData.documentCategory.label),
      MapEntry('Domaine', document.extractedData.documentDomain.label),
    ];

    for (final entry in metadata) {
      _writeKeyValueRow(
        sheet: summarySheet,
        rowIndex: summaryRow,
        key: entry.key,
        value: entry.value,
        keyStyle: keyStyle,
        valueStyle: valueStyle,
      );
      summaryRow++;
    }

    summaryRow++;
    _writeSectionHeader(
      summarySheet,
      summaryRow,
      'Donnees extraites',
      sectionStyle,
    );
    summaryRow++;

    final extractedEntries = document.extractedData.toDisplayEntries();
    for (final entry in extractedEntries) {
      _writeKeyValueRow(
        sheet: summarySheet,
        rowIndex: summaryRow,
        key: entry.key,
        value: entry.value,
        keyStyle: keyStyle,
        valueStyle: valueStyle,
      );
      summaryRow++;
    }

    summaryRow++;
    _writeSectionHeader(summarySheet, summaryRow, 'Apercu texte', sectionStyle);
    summaryRow++;
    final ocrPreview = _truncate(
      document.ocrText.trim().isEmpty ? 'Texte vide.' : document.ocrText.trim(),
      2000,
    );
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow),
    );
    summarySheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
      TextCellValue(ocrPreview),
      cellStyle: ocrStyle,
    );
    summarySheet.setRowHeight(summaryRow, 120);

    dataSheet.setColumnWidth(0, 30);
    dataSheet.setColumnWidth(1, 55);
    dataSheet.updateCell(
      CellIndex.indexByString('A1'),
      TextCellValue('Champ'),
      cellStyle: sectionStyle,
    );
    dataSheet.updateCell(
      CellIndex.indexByString('B1'),
      TextCellValue('Valeur'),
      cellStyle: sectionStyle,
    );

    var dataRow = 1;
    for (final entry in extractedEntries) {
      dataSheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: dataRow),
        TextCellValue(entry.key),
        cellStyle: keyStyle,
      );
      dataSheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dataRow),
        TextCellValue(entry.value),
        cellStyle: valueStyle,
      );
      dataRow++;
    }

    ocrSheet.setColumnWidth(0, 10);
    ocrSheet.setColumnWidth(1, 100);
    ocrSheet.updateCell(
      CellIndex.indexByString('A1'),
      TextCellValue('Ligne'),
      cellStyle: sectionStyle,
    );
    ocrSheet.updateCell(
      CellIndex.indexByString('B1'),
      TextCellValue('Texte scanne'),
      cellStyle: sectionStyle,
    );

    final ocrLines = document.ocrText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (ocrLines.isEmpty) {
      ocrSheet.updateCell(
        CellIndex.indexByString('A2'),
        IntCellValue(1),
        cellStyle: keyStyle,
      );
      ocrSheet.updateCell(
        CellIndex.indexByString('B2'),
        TextCellValue('Texte vide.'),
        cellStyle: ocrStyle,
      );
    } else {
      for (var i = 0; i < ocrLines.length; i++) {
        final rowIndex = i + 1;
        ocrSheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          IntCellValue(i + 1),
          cellStyle: keyStyle,
        );
        ocrSheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          TextCellValue(ocrLines[i]),
          cellStyle: ocrStyle,
        );
      }
    }

    final fileBytes = excel.save();
    if (fileBytes == null || fileBytes.isEmpty) {
      throw Exception('Generation XLSX impossible');
    }

    return Uint8List.fromList(fileBytes);
  }

  Future<Uint8List> _buildPdf(ScannedDocument document) async {
    final pdf = pw.Document();
    final extractedEntries = document.extractedData.toDisplayEntries();
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(document.createdAt);
    final exportedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final brandLogo = await _loadPdfBrandLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.7),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (brandLogo != null)
                pw.SizedBox(
                  height: 16,
                  child: pw.Image(brandLogo, fit: pw.BoxFit.contain),
                )
              else
                pw.Text(
                  'Scanner Documents Offline',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.Text(
                'Rapport local',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  document.title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Rapport extraction offline genere le $exportedAt',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(child: _pdfMetricCard('Date creation', createdAt)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfMetricCard('Pages', '${document.imagePaths.length}'),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfMetricCard(
                  'Type / Domaine',
                  '${document.extractedData.documentCategory.label} / ${document.extractedData.documentDomain.label}',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('Donnees extraites'),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                children: [
                  _pdfTableCell('Champ', isHeader: true),
                  _pdfTableCell('Valeur', isHeader: true),
                ],
              ),
              ...extractedEntries.map(
                (entry) => pw.TableRow(
                  children: [
                    _pdfTableCell(entry.key),
                    _pdfTableCell(entry.value),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _pdfSectionTitle('Texte scanne'),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              _truncate(
                document.ocrText.trim().isEmpty
                    ? 'Texte vide.'
                    : document.ocrText.trim(),
                12000,
              ),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );

    for (var i = 0; i < document.imagePaths.length; i++) {
      final imagePath = document.imagePaths[i];
      final file = File(imagePath);
      if (!file.existsSync()) {
        continue;
      }

      try {
        final bytes = await file.readAsBytes();
        final image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Page scan ${i + 1} / ${document.imagePaths.length}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Center(
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (_) {
        // Ignore corrupted/unreadable image files and continue PDF generation.
      }
    }

    return Uint8List.fromList(await pdf.save());
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}\n\n... (texte tronque)';
  }

  void _writeSectionHeader(
    Sheet sheet,
    int rowIndex,
    String title,
    CellStyle style,
  ) {
    final start = CellIndex.indexByColumnRow(
      columnIndex: 0,
      rowIndex: rowIndex,
    );
    final end = CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex);
    sheet.merge(start, end);
    sheet.updateCell(start, TextCellValue(title), cellStyle: style);
    sheet.setRowHeight(rowIndex, 24);
  }

  void _writeKeyValueRow({
    required Sheet sheet,
    required int rowIndex,
    required String key,
    required String value,
    required CellStyle keyStyle,
    required CellStyle valueStyle,
  }) {
    final keyCell = CellIndex.indexByColumnRow(
      columnIndex: 0,
      rowIndex: rowIndex,
    );
    final valueCell = CellIndex.indexByColumnRow(
      columnIndex: 1,
      rowIndex: rowIndex,
    );
    final valueEnd = CellIndex.indexByColumnRow(
      columnIndex: 3,
      rowIndex: rowIndex,
    );
    sheet.merge(valueCell, valueEnd);
    sheet.updateCell(keyCell, TextCellValue(key), cellStyle: keyStyle);
    sheet.updateCell(valueCell, TextCellValue(value), cellStyle: valueStyle);
    sheet.setRowHeight(rowIndex, 22);
  }

  pw.Widget _pdfMetricCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.teal100, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String label) {
    return pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 13,
        color: PdfColors.teal900,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.teal900 : PdfColors.black,
        ),
      ),
    );
  }

  String _normalizeValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Non detecte';
    }
    return value.trim();
  }

  String _txtLine(String label, String value) {
    return '${label.padRight(16)}: $value';
  }

  String _escapeCsv(String input) {
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<pw.MemoryImage?> _loadPdfBrandLogo() async {
    try {
      final data = await rootBundle.load(
        'images/scanner_full_logo_transparent.png',
      );
      return pw.MemoryImage(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _getExportsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(appDir.path, 'exports'));
    await exportsDir.create(recursive: true);
    return exportsDir;
  }
}
