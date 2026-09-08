import 'dart:typed_data';

import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  /// Diisi ketika halaman Export Data dibuka dari halaman Laporan.
  /// Periode export akan langsung mengikuti periode laporan yang sedang dipilih.
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  String selectedFilter = 'Hari Ini';
  late DateTime startDate;
  late DateTime endDate;
  bool isExporting = false;

  final NumberFormat currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day);

    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      selectedFilter = 'Custom';
      startDate = _dateOnly(widget.initialStartDate!);
      endDate = _dateOnly(widget.initialEndDate!);
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime getStartDate() {
    final now = DateTime.now();

    switch (selectedFilter) {
      case 'Hari Ini':
        return DateTime(now.year, now.month, now.day);
      case 'Minggu Ini':
        final firstDay = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(firstDay.year, firstDay.month, firstDay.day);
      case 'Bulan Ini':
        return DateTime(now.year, now.month, 1);
      case 'Tahun Ini':
        return DateTime(now.year, 1, 1);
      case 'Custom':
      default:
        return _dateOnly(startDate);
    }
  }

  DateTime getEndDate() {
    if (selectedFilter == 'Custom') {
      return DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
    }

    return DateTime.now();
  }

  bool _isDateInSelectedRange(DateTime date) {
    final start = getStartDate();
    final end = getEndDate();

    return !date.isBefore(start) && !date.isAfter(end);
  }

  Future<void> chooseDate(bool choosingStartDate) async {
    final initialDate = choosingStartDate ? startDate : endDate;

    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: initialDate,
    );

    if (result == null || !mounted) return;

    setState(() {
      if (choosingStartDate) {
        startDate = _dateOnly(result);

        if (startDate.isAfter(endDate)) {
          endDate = startDate;
        }
      } else {
        endDate = _dateOnly(result);

        if (endDate.isBefore(startDate)) {
          startDate = endDate;
        }
      }
    });
  }

  DateTime? _readDate(dynamic rawDate) {
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }

    if (rawDate is DateTime) {
      return rawDate;
    }

    if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }

    return null;
  }

  double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  List<_ExportRow> _buildExportRows({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> transactionDocs,
    required Map<String, String> envelopeNames,
    required double initialBalance,
    required DateTime? initialBalanceDate,
  }) {
    final rows = <_ExportRow>[];
    final periodStart = getStartDate();
    final periodEnd = getEndDate();

    // Saldo awal dibawa sebagai saldo pembuka untuk setiap periode laporan
    // setelah tanggal saldo awal dibuat. Jika tanggal lama belum tersimpan,
    // saldo awal tetap dimasukkan pada awal periode agar tidak hilang.
    final canIncludeInitialBalance = initialBalance > 0 &&
        (initialBalanceDate == null || !initialBalanceDate.isAfter(periodEnd));

    if (canIncludeInitialBalance) {
      final balanceRowDate = initialBalanceDate == null ||
              initialBalanceDate.isBefore(periodStart)
          ? periodStart
          : initialBalanceDate;

      rows.add(
        _ExportRow(
          date: balanceRowDate,
          description: 'Saldo Awal',
          category: 'Saldo Awal',
          isIncome: true,
          amount: initialBalance,
          isInitialBalance: true,
        ),
      );
    }

    for (final document in transactionDocs) {
      final data = document.data();
      final date = _readDate(data['date'] ?? data['createdAt']);

      if (date == null || !_isDateInSelectedRange(date)) {
        continue;
      }

      final isIncome = data['type'] == 'income';
      final envelopeId = (data['envelopeId'] ?? '').toString();

      String category;
      if (envelopeId.isNotEmpty) {
        category = envelopeNames[envelopeId] ?? 'Amplop';
      } else {
        category = isIncome ? 'Pemasukan' : 'Tanpa amplop / Lainnya';
      }

      final rawTitle = (data['title'] ?? data['note'] ?? '').toString().trim();

      rows.add(
        _ExportRow(
          date: date,
          description: rawTitle.isEmpty ? 'Tanpa keterangan' : rawTitle,
          category: category,
          isIncome: isIncome,
          amount: _readAmount(data['amount']),
        ),
      );
    }

    // Saldo awal selalu berada paling atas, lalu transaksi dari tanggal lama.
    rows.sort((a, b) {
      if (a.isInitialBalance && !b.isInitialBalance) return -1;
      if (!a.isInitialBalance && b.isInitialBalance) return 1;

      final dateResult = a.date.compareTo(b.date);
      if (dateResult != 0) return dateResult;

      return a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          );
    });

    return rows;
  }

  double _calculateIncome(List<_ExportRow> rows) {
    return rows
        .where((row) => row.isIncome)
        .fold<double>(0, (total, row) => total + row.amount);
  }

  double _calculateExpense(List<_ExportRow> rows) {
    return rows
        .where((row) => !row.isIncome)
        .fold<double>(0, (total, row) => total + row.amount);
  }

  double _calculateInitialBalance(List<_ExportRow> rows) {
    return rows
        .where((row) => row.isInitialBalance)
        .fold<double>(0, (total, row) => total + row.amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  String get _periodLabel {
    return '${_formatDate(getStartDate())} - ${_formatDate(getEndDate())}';
  }

  String get _filePeriod {
    final formatter = DateFormat('yyyyMMdd');
    return '${formatter.format(getStartDate())}_${formatter.format(getEndDate())}';
  }

  xls.CellIndex _cellIndex(int columnIndex, int rowIndex) {
    return xls.CellIndex.indexByColumnRow(
      columnIndex: columnIndex,
      rowIndex: rowIndex,
    );
  }

  void _setCellStyle(
    xls.Sheet sheet,
    int rowIndex,
    int columnIndex,
    xls.CellStyle style,
  ) {
    sheet.cell(_cellIndex(columnIndex, rowIndex)).cellStyle = style;
  }

  Future<void> _saveFile({
    required String name,
    required Uint8List bytes,
    required String extension,
  }) async {
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan laporan AmplopKu',
      fileName: '$name.$extension',
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );

    if (savedPath == null) {
      throw Exception('Penyimpanan file dibatalkan');
    }
  }

  Future<void> exportExcel(List<_ExportRow> rows) async {
    if (isExporting) return;

    setState(() => isExporting = true);

    try {
      final totalInitialBalance = _calculateInitialBalance(rows);
      final totalIncome = _calculateIncome(rows);
      final totalExpense = _calculateExpense(rows);
      final finalBalance = totalIncome - totalExpense;

      final excel = xls.Excel.createExcel();
      final sheet = excel['Laporan Keuangan'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final thinBorder = xls.Border(borderStyle: xls.BorderStyle.Thin);

      final titleStyle = xls.CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
      );

      final sectionStyle = xls.CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: xls.HorizontalAlign.Left,
        verticalAlign: xls.VerticalAlign.Center,
      );

      final labelStyle = xls.CellStyle(
        bold: true,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final valueStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Right,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final headerStyle = xls.CellStyle(
        bold: true,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final bodyTextStyle = xls.CellStyle(
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final bodyCenterStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final bodyAmountStyle = xls.CellStyle(
        horizontalAlign: xls.HorizontalAlign.Right,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      // Judul laporan.
      sheet.merge(
        xls.CellIndex.indexByString('A1'),
        xls.CellIndex.indexByString('G1'),
      );
      sheet.cell(xls.CellIndex.indexByString('A1')).value =
          xls.TextCellValue('LAPORAN KEUANGAN AMPLOPKU');
      sheet.cell(xls.CellIndex.indexByString('A1')).cellStyle = titleStyle;
      sheet.setRowHeight(0, 28);

      // Periode laporan.
      sheet.cell(xls.CellIndex.indexByString('A2')).value = xls.TextCellValue('Periode');
      sheet.cell(xls.CellIndex.indexByString('A2')).cellStyle = sectionStyle;
      sheet.merge(
        xls.CellIndex.indexByString('B2'),
        xls.CellIndex.indexByString('G2'),
      );
      sheet.cell(xls.CellIndex.indexByString('B2')).value =
          xls.TextCellValue(_periodLabel);
      sheet.setRowHeight(1, 22);

      // Ringkasan.
      sheet.merge(
        xls.CellIndex.indexByString('A4'),
        xls.CellIndex.indexByString('G4'),
      );
      sheet.cell(xls.CellIndex.indexByString('A4')).value =
          xls.TextCellValue('RINGKASAN');
      sheet.cell(xls.CellIndex.indexByString('A4')).cellStyle = sectionStyle;

      final summaryRows = <List<String>>[
        ['Saldo Awal', currency.format(totalInitialBalance)],
        ['Total Pemasukan', currency.format(totalIncome)],
        ['Total Pengeluaran', currency.format(totalExpense)],
        ['Saldo Akhir', currency.format(finalBalance)],
      ];

      for (int index = 0; index < summaryRows.length; index++) {
        final excelRow = 4 + index;
        sheet.cell(_cellIndex(0, excelRow)).value =
            xls.TextCellValue(summaryRows[index][0]);
        sheet.cell(_cellIndex(1, excelRow)).value =
            xls.TextCellValue(summaryRows[index][1]);
        _setCellStyle(sheet, excelRow, 0, labelStyle);
        _setCellStyle(sheet, excelRow, 1, valueStyle);
        sheet.setRowHeight(excelRow, 21);
      }

      // Header tabel transaksi.
      const tableHeaderRow = 9;
      final headers = <String>[
        'Tanggal',
        'Keterangan',
        'Kategori',
        'Jenis',
        'Pemasukan',
        'Pengeluaran',
        'Saldo',
      ];

      for (int column = 0; column < headers.length; column++) {
        sheet.cell(_cellIndex(column, tableHeaderRow)).value =
            xls.TextCellValue(headers[column]);
        _setCellStyle(sheet, tableHeaderRow, column, headerStyle);
      }
      sheet.setRowHeight(tableHeaderRow, 28);

      double runningBalance = 0;
      int currentRow = tableHeaderRow + 1;

      if (rows.isEmpty) {
        sheet.merge(
          _cellIndex(0, currentRow),
          _cellIndex(6, currentRow),
        );
        sheet.cell(_cellIndex(0, currentRow)).value =
            xls.TextCellValue('Tidak ada data pada periode ini');
        sheet.cell(_cellIndex(0, currentRow)).cellStyle = bodyCenterStyle;
        sheet.setRowHeight(currentRow, 24);
      } else {
        for (final row in rows) {
          runningBalance += row.isIncome ? row.amount : -row.amount;

          final values = <String>[
            _formatDate(row.date),
            row.description,
            row.category,
            row.isIncome ? 'Pemasukan' : 'Pengeluaran',
            row.isIncome ? currency.format(row.amount) : '-',
            row.isIncome ? '-' : currency.format(row.amount),
            currency.format(runningBalance),
          ];

          for (int column = 0; column < values.length; column++) {
            sheet.cell(_cellIndex(column, currentRow)).value =
                xls.TextCellValue(values[column]);

            if (column == 0 || column == 3) {
              _setCellStyle(sheet, currentRow, column, bodyCenterStyle);
            } else if (column >= 4) {
              _setCellStyle(sheet, currentRow, column, bodyAmountStyle);
            } else {
              _setCellStyle(sheet, currentRow, column, bodyTextStyle);
            }
          }

          sheet.setRowHeight(currentRow, 23);
          currentRow++;
        }
      }

      // Lebar kolom dibuat cukup besar agar tidak muncul tanda #######.
      sheet.setColumnWidth(0, 16);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 24);
      sheet.setColumnWidth(3, 16);
      sheet.setColumnWidth(4, 20);
      sheet.setColumnWidth(5, 20);
      sheet.setColumnWidth(6, 20);

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('File Excel tidak dapat dibuat');
      }

      final fileName = 'Laporan_Keuangan_AmplopKu_$_filePeriod';

      await _saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        extension: 'xlsx',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel berhasil dibuat')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export Excel gagal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  Future<void> exportPDF(List<_ExportRow> rows) async {
    if (isExporting) return;

    setState(() => isExporting = true);

    try {
      final totalInitialBalance = _calculateInitialBalance(rows);
      final totalIncome = _calculateIncome(rows);
      final totalExpense = _calculateExpense(rows);
      final finalBalance = totalIncome - totalExpense;

      double runningBalance = 0;
      final pdfRows = <List<String>>[];

      for (final row in rows) {
        runningBalance += row.isIncome ? row.amount : -row.amount;

        pdfRows.add([
          _formatDate(row.date),
          row.description,
          row.category,
          row.isIncome ? 'Pemasukan' : 'Pengeluaran',
          row.isIncome ? currency.format(row.amount) : '-',
          row.isIncome ? '-' : currency.format(row.amount),
          currency.format(runningBalance),
        ]);
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            pw.Text(
              'Laporan Keuangan AmplopKu',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Periode: $_periodLabel',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfSummaryItem(
                    'Saldo Awal',
                    currency.format(totalInitialBalance),
                  ),
                  _pdfSummaryItem(
                    'Total Pemasukan',
                    currency.format(totalIncome),
                  ),
                  _pdfSummaryItem(
                    'Total Pengeluaran',
                    currency.format(totalExpense),
                  ),
                  _pdfSummaryItem(
                    'Saldo Akhir',
                    currency.format(finalBalance),
                    bold: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            if (pdfRows.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                ),
                child: pw.Center(
                  child: pw.Text('Tidak ada data pada periode ini'),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Tanggal',
                  'Keterangan',
                  'Kategori',
                  'Jenis',
                  'Pemasukan',
                  'Pengeluaran',
                  'Saldo',
                ],
                data: pdfRows,
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.6,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.purple700,
                ),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(64),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(1.25),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FixedColumnWidth(76),
                  5: pw.FixedColumnWidth(76),
                  6: pw.FixedColumnWidth(76),
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
              ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Saldo awal dibawa sebagai saldo pembuka dan sudah dihitung dalam total pemasukan.',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'Laporan_Keuangan_AmplopKu_$_filePeriod';

      await _saveFile(
        name: fileName,
        bytes: bytes,
        extension: 'pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF berhasil dibuat')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export PDF gagal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  pw.Widget _pdfSummaryItem(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: bold
                ? pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  )
                : const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 6,
        ),
        title: Text(title),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildExportContent({
    required List<_ExportRow> rows,
  }) {
    final totalInitialBalance = _calculateInitialBalance(rows);
    final totalIncome = _calculateIncome(rows);
    final totalExpense = _calculateExpense(rows);
    final finalBalance = totalIncome - totalExpense;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        DropdownButtonFormField<String>(
          value: selectedFilter,
          decoration: const InputDecoration(
            labelText: 'Filter Periode',
            border: OutlineInputBorder(),
          ),
          items: const [
            'Hari Ini',
            'Minggu Ini',
            'Bulan Ini',
            'Tahun Ini',
            'Custom',
          ]
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedFilter = value);
          },
        ),
        if (selectedFilter == 'Custom') ...[
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;

              final startButton = OutlinedButton.icon(
                onPressed: () => chooseDate(true),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Awal: ${_formatDate(startDate)}'),
              );

              final endButton = OutlinedButton.icon(
                onPressed: () => chooseDate(false),
                icon: const Icon(Icons.event_available_outlined),
                label: Text('Akhir: ${_formatDate(endDate)}'),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    startButton,
                    const SizedBox(height: 8),
                    endButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: startButton),
                  const SizedBox(width: 10),
                  Expanded(child: endButton),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Saldo awal otomatis dibawa sebagai saldo pembuka dan ikut dihitung sebagai pemasukan pada laporan.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _summaryCard(
          title: 'Total Pemasukan',
          value: currency.format(totalIncome),
          subtitle: totalInitialBalance > 0
              ? 'Termasuk saldo awal ${currency.format(totalInitialBalance)}'
              : 'Belum ada saldo awal yang dapat dihitung',
        ),
        _summaryCard(
          title: 'Total Pengeluaran',
          value: currency.format(totalExpense),
        ),
        _summaryCard(
          title: 'Saldo Akhir',
          value: currency.format(finalBalance),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isExporting ? null : () => exportExcel(rows),
            icon: const Icon(Icons.table_chart_rounded),
            label: isExporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Export Excel'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isExporting ? null : () => exportPDF(rows),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: isExporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Export PDF'),
          ),
        ),
      ],
    );
  }

  Widget _loadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestore.financeStream(user.uid),
        builder: (context, financeSnapshot) {
          if (financeSnapshot.hasError) {
            return _errorState('Data saldo awal gagal dimuat.');
          }

          if (!financeSnapshot.hasData) {
            return _loadingState();
          }

          final financeData = financeSnapshot.data?.data() ?? {};
          final initialBalance =
              _readAmount(financeData['income']);
          final initialBalanceDate = _readDate(financeData['incomeDate']);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore.getEnvelopes(user.uid),
            builder: (context, envelopeSnapshot) {
              if (envelopeSnapshot.hasError) {
                return _errorState('Data amplop gagal dimuat.');
              }

              if (!envelopeSnapshot.hasData) {
                return _loadingState();
              }

              final envelopeNames = <String, String>{};
              for (final document in envelopeSnapshot.data!.docs) {
                envelopeNames[document.id] =
                    (document.data()['nama'] ?? 'Amplop').toString();
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestore.getTransactions(user.uid),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.hasError) {
                    return _errorState('Data transaksi gagal dimuat.');
                  }

                  if (!transactionSnapshot.hasData) {
                    return _loadingState();
                  }

                  final rows = _buildExportRows(
                    transactionDocs: transactionSnapshot.data!.docs,
                    envelopeNames: envelopeNames,
                    initialBalance: initialBalance,
                    initialBalanceDate: initialBalanceDate,
                  );

                  return _buildExportContent(rows: rows);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ExportRow {
  const _ExportRow({
    required this.date,
    required this.description,
    required this.category,
    required this.isIncome,
    required this.amount,
    this.isInitialBalance = false,
  });

  final DateTime date;
  final String description;
  final String category;
  final bool isIncome;
  final double amount;
  final bool isInitialBalance;
}
