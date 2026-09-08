import 'dart:math' as math;

import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/screens/export_data_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  late Future<_ReportPayload> _reportFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
    _reportFuture = _loadReport();
  }

  DateTime get _endExclusive =>
      DateTime(_endDate.year, _endDate.month, _endDate.day)
          .add(const Duration(days: 1));

  Future<_ReportPayload> _loadReport() async {
    final user = AuthService().currentUser;
    if (user == null) {
      throw const _ReportException(
        'Sesi pengguna tidak ditemukan. Silakan login kembali.',
      );
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Semua request dimulai terlebih dahulu supaya pengambilan data lebih cepat.
    // Tidak memakai orderBy agar dokumen lama yang belum mempunyai field tanggal
    // tidak membuat halaman laporan gagal dimuat.
    final financeFuture =
        userRef.collection('settings').doc('finance').get();
    final envelopeFuture = userRef.collection('envelopes').get();
    final transactionFuture = userRef.collection('transactions').get();

    final financeSnapshot = await financeFuture;
    final envelopeSnapshot = await envelopeFuture;
    final transactionSnapshot = await transactionFuture;

    final envelopeNames = <String, String>{};
    for (final document in envelopeSnapshot.docs) {
      final data = document.data();
      final name = (data['nama'] ?? data['name'] ?? 'Lainnya')
          .toString()
          .trim();
      envelopeNames[document.id] = name.isEmpty ? 'Lainnya' : name;
    }

    final transactions = <_ReportTransaction>[];
    for (final document in transactionSnapshot.docs) {
      try {
        final data = document.data();
        final amount = _readNumber(data['amount']);
        if (amount <= 0) continue;

        final rawType = (data['type'] ?? 'expense')
            .toString()
            .trim()
            .toLowerCase();
        final type = rawType == 'income'
            ? _TransactionKind.income
            : _TransactionKind.expense;

        final date = _readDate(data['date']) ??
            _readDate(data['createdAt']) ??
            DateTime.now();

        if (!_isInsideSelectedRange(date)) continue;

        final title = (data['title'] ?? data['note'] ?? '')
            .toString()
            .trim();
        final description = (data['description'] ?? '')
            .toString()
            .trim();
        final envelopeId = (data['envelopeId'] ?? '')
            .toString()
            .trim();

        transactions.add(
          _ReportTransaction(
            id: document.id,
            title: title.isEmpty
                ? (type == _TransactionKind.income
                    ? 'Pemasukan'
                    : 'Pengeluaran')
                : title,
            description: description,
            amount: amount,
            type: type,
            envelopeId: envelopeId,
            date: date,
          ),
        );
      } catch (_) {
        // Satu dokumen yang formatnya rusak dilewati agar halaman tidak putih.
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    double totalIncome = 0;
    double totalExpense = 0;
    final categoryTotals = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == _TransactionKind.income) {
        totalIncome += transaction.amount;
        continue;
      }

      totalExpense += transaction.amount;
      final categoryName = transaction.envelopeId.isEmpty
          ? 'Lainnya'
          : (envelopeNames[transaction.envelopeId] ?? 'Lainnya');
      categoryTotals[categoryName] =
          (categoryTotals[categoryName] ?? 0) + transaction.amount;
    }

    final financeData = financeSnapshot.data() ?? <String, dynamic>{};
    final openingIncome = _readNumber(financeData['income']);
    final openingIncomeDate = _readDate(financeData['incomeDate']);

    // Saldo awal dihitung sebagai pemasukan hanya pada periode tanggal inputnya.
    if (openingIncome > 0 &&
        (openingIncomeDate == null ||
            _isInsideSelectedRange(openingIncomeDate))) {
      totalIncome += openingIncome;
    }

    final categories = _buildCategorySlices(categoryTotals);

    return _ReportPayload(
      income: totalIncome,
      expense: totalExpense,
      categories: categories,
      transactions: transactions,
    );
  }

  List<_CategorySlice> _buildCategorySlices(
    Map<String, double> totals,
  ) {
    final entries = totals.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return const <_CategorySlice>[];

    // Referensi menampilkan empat bagian utama. Jika kategori lebih banyak,
    // kategori sisanya digabung menjadi "Lainnya" agar label tetap rapi.
    final normalized = <MapEntry<String, double>>[];
    if (entries.length <= 4) {
      normalized.addAll(entries);
    } else {
      normalized.addAll(entries.take(3));
      final otherTotal = entries
          .skip(3)
          .fold<double>(0, (sum, entry) => sum + entry.value);
      normalized.add(MapEntry<String, double>('Lainnya', otherTotal));
    }

    const palette = <Color>[
      AppColors.primary,
      AppColors.secondary,
      AppColors.accentBlue,
      AppColors.accentPink,
      AppColors.primaryDark,
      AppColors.primaryLight,
    ];

    return List<_CategorySlice>.generate(
      normalized.length,
      (index) => _CategorySlice(
        label: normalized[index].key,
        amount: normalized[index].value,
        color: palette[index % palette.length],
      ),
    );
  }

  Future<void> _refresh() async {
    final future = _loadReport();
    setState(() => _reportFuture = future);

    try {
      await future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      helpText: 'Pilih periode laporan',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );

    if (result == null || !mounted) return;

    setState(() {
      _startDate = DateTime(
        result.start.year,
        result.start.month,
        result.start.day,
      );
      _endDate = DateTime(
        result.end.year,
        result.end.month,
        result.end.day,
      );
      _reportFuture = _loadReport();
    });
  }

  void _openExport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportDataScreen(
          initialStartDate: _startDate,
          initialEndDate: _endDate,
        ),
      ),
    );
  }

  bool _isInsideSelectedRange(DateTime date) {
    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );
    return !date.isBefore(start) && date.isBefore(_endExclusive);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final isDesktop = viewport.maxWidth >= 1000;
            final horizontalPadding = viewport.maxWidth >= 1400
                ? 36.0
                : viewport.maxWidth >= 1000
                    ? 28.0
                    : viewport.maxWidth >= 600
                        ? 22.0
                        : 16.0;
            final bottomPadding = isDesktop ? 36.0 : 104.0;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isDesktop ? 26 : 18,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0.0,
                      viewport.maxHeight - (isDesktop ? 62.0 : 124.0),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1480),
                      child: FutureBuilder<_ReportPayload>(
                        future: _reportFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return _buildLoadingView();
                          }

                          if (snapshot.hasError) {
                            return _buildErrorView(snapshot.error);
                          }

                          final data = snapshot.data ??
                              const _ReportPayload.empty();
                          return _buildReportContent(data);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const SizedBox(
      height: 500,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorView(Object? error) {
    final message = error is _ReportException
        ? error.message
        : (error?.toString().replaceFirst('Exception: ', '') ??
            'Data laporan gagal dimuat.');

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 14),
              const Text(
                'Laporan belum dapat ditampilkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent(_ReportPayload data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildSummaryCards(data),
        const SizedBox(height: 20),
        _buildChartCard(data),
        const SizedBox(height: 20),
        _buildTransactionCard(data.transactions),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 570;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan',
              style: TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 9,
          runSpacing: 9,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_month_rounded, size: 20),
              label: const Text('Pilih tanggal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.06),
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _openExport,
              icon: const Icon(Icons.file_download_outlined, size: 20),
              label: const Text('Export Excel/PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.06),
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            SizedBox(
              width: 50,
              height: 50,
              child: OutlinedButton(
                onPressed: _refresh,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.06),
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(0.24),
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(Icons.refresh_rounded),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 16),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(_ReportPayload data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 610;
        final expenseCard = _SummaryCard(
          title: 'Uang Keluar',
          amount: _formatRupiah(data.expense),
          amountColor: AppColors.primaryDark,
          borderColor: AppColors.primaryDark,
          backgroundColor: AppColors.primarySoft.withOpacity(0.72),
          highlighted: true,
        );
        final incomeCard = _SummaryCard(
          title: 'Uang Masuk',
          amount: _formatRupiah(data.income),
          amountColor: AppColors.primary,
          borderColor: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(0.075),
          highlighted: true,
        );

        if (compact) {
          return Column(
            children: [
              expenseCard,
              const SizedBox(height: 12),
              incomeCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: expenseCard),
            const SizedBox(width: 16),
            Expanded(child: incomeCard),
          ],
        );
      },
    );
  }

  Widget _buildChartCard(_ReportPayload data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengeluaran per Kategori',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Perbandingan penggunaan uang berdasarkan amplop',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final showConnectorLabels = constraints.maxWidth >= 680;
              final chartHeight = constraints.maxWidth >= 1200
                  ? 380.0
                  : constraints.maxWidth >= 820
                      ? 350.0
                      : constraints.maxWidth >= 560
                          ? 310.0
                          : 250.0;
              return Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _DonutReportPainter(
                        categories: data.categories,
                        total: data.expense,
                        showLabels: showConnectorLabels,
                        emptyColor: Theme.of(context).dividerColor,
                        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (!showConnectorLabels) ...[
                    const SizedBox(height: 8),
                    _buildCompactLegend(data.categories, data.expense),
                  ],
                  if (data.categories.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Belum ada pengeluaran pada periode ini.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegend(
    List<_CategorySlice> categories,
    double total,
  ) {
    if (categories.isEmpty || total <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: categories.map((category) {
        final percentage = total <= 0
            ? 0
            : ((category.amount / total) * 100).round();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percentage%  •  ${_formatRupiah(category.amount)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionCard(
    List<_ReportTransaction> transactions,
  ) {
    final visibleTransactions = transactions.take(10).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${transactions.length} transaksi',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visibleTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Belum ada transaksi pada periode ini.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List<Widget>.generate(
              visibleTransactions.length,
              (index) {
                final transaction = visibleTransactions[index];
                final isIncome =
                    transaction.type == _TransactionKind.income;
                final color = isIncome
                    ? AppColors.primary
                    : AppColors.accentPink;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  transaction.description.isEmpty
                                      ? _formatDate(transaction.date)
                                      : '${transaction.description} • ${_formatDate(transaction.date)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${isIncome ? '+' : '-'}${_formatRupiah(transaction.amount)}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != visibleTransactions.length - 1)
                      Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  static double _readNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is! String) return 0;

    var text = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (text.isEmpty) return 0;

    if (text.contains(',') && text.contains('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (text.contains(',')) {
      final lastPart = text.split(',').last;
      text = lastPart.length == 3
          ? text.replaceAll(',', '')
          : text.replaceAll(',', '.');
    } else if (text.contains('.')) {
      final sections = text.split('.');
      if (sections.length > 2 || sections.last.length == 3) {
        text = text.replaceAll('.', '');
      }
    }

    return double.tryParse(text) ?? 0;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static String _formatRupiah(num value) {
    final isNegative = value < 0;
    final raw = value.abs().round().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < raw.length; index++) {
      if (index > 0 && (raw.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(raw[index]);
    }

    return '${isNegative ? '-' : ''}Rp${buffer.toString()}';
  }

  static String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.amountColor,
    required this.borderColor,
    required this.backgroundColor,
    this.highlighted = false,
  });

  final String title;
  final String amount;
  final Color amountColor;
  final Color borderColor;
  final Color backgroundColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackground = theme.brightness == Brightness.dark
        ? borderColor.withOpacity(0.14)
        : backgroundColor;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: borderColor,
          width: highlighted ? 2 : 1.3,
        ),
        boxShadow: highlighted
            ? const <BoxShadow>[]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 30,
                height: 1,
                color: amountColor,
                fontWeight: highlighted
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutReportPainter extends CustomPainter {
  const _DonutReportPainter({
    required this.categories,
    required this.total,
    required this.showLabels,
    required this.emptyColor,
    required this.labelColor,
  });

  final List<_CategorySlice> categories;
  final double total;
  final bool showLabels;
  final Color emptyColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final labelSpace = showLabels ? math.min(145.0, size.width * 0.18) : 0.0;
    final availableWidth = size.width - (labelSpace * 2) - 36;
    final radiusByWidth = math.max(55.0, availableWidth / 2);
    final radiusByHeight = size.height * (showLabels ? 0.30 : 0.29);
    final radius = math.min(radiusByWidth, radiusByHeight);
    final strokeWidth = math.max(30.0, radius * 0.46);
    final center = Offset(
      size.width / 2,
      showLabels ? size.height * 0.53 : size.height * 0.50,
    );
    final chartRect = Rect.fromCircle(center: center, radius: radius);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (categories.isEmpty || total <= 0) {
      arcPaint.color = emptyColor;
      canvas.drawArc(chartRect, 0, math.pi * 2, false, arcPaint);
      return;
    }

    const gapAngle = 0.035;
    var startAngle = -math.pi / 2;
    final labels = <_ChartLabel>[];

    for (final category in categories) {
      final ratio = (category.amount / total).clamp(0.0, 1.0).toDouble();
      final fullSweep = math.pi * 2 * ratio;
      final visibleSweep = math.max(0.0, fullSweep - gapAngle);

      arcPaint.color = category.color;
      canvas.drawArc(
        chartRect,
        startAngle + (gapAngle / 2),
        visibleSweep,
        false,
        arcPaint,
      );

      final middleAngle = startAngle + (fullSweep / 2);
      labels.add(
        _ChartLabel(
          category: category,
          angle: middleAngle,
          desiredY: center.dy + math.sin(middleAngle) * (radius + 30),
          isRight: math.cos(middleAngle) >= 0,
        ),
      );

      startAngle += fullSweep;
    }

    if (!showLabels) return;

    final leftLabels = labels.where((label) => !label.isRight).toList();
    final rightLabels = labels.where((label) => label.isRight).toList();
    _arrangeLabels(leftLabels, size.height);
    _arrangeLabels(rightLabels, size.height);

    final connectorPaint = Paint()
      ..color = labelColor.withOpacity(0.48)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = labelColor.withOpacity(0.48)
      ..style = PaintingStyle.fill;

    for (final label in labels) {
      final direction = label.isRight ? 1.0 : -1.0;
      final outerRadius = radius + (strokeWidth / 2) + 2;
      final startPoint = Offset(
        center.dx + math.cos(label.angle) * outerRadius,
        center.dy + math.sin(label.angle) * outerRadius,
      );
      final elbowX = center.dx + direction * (radius + strokeWidth + 18);
      final lineEndX = label.isRight
          ? size.width - labelSpace + 4
          : labelSpace - 4;
      final elbowPoint = Offset(elbowX, label.adjustedY);
      final endPoint = Offset(lineEndX, label.adjustedY);

      final path = Path()
        ..moveTo(startPoint.dx, startPoint.dy)
        ..lineTo(elbowPoint.dx, elbowPoint.dy)
        ..lineTo(endPoint.dx, endPoint.dy);
      canvas.drawPath(path, connectorPaint);
      canvas.drawCircle(endPoint, 3.3, dotPaint);

      final maxTextWidth = math.max(65.0, labelSpace - 18);
      final textPainter = TextPainter(
        text: TextSpan(
          text: _shortLabel(label.category.label),
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        maxLines: 1,
        ellipsis: '...',
        textAlign: label.isRight ? TextAlign.left : TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxTextWidth);

      final textX = label.isRight
          ? endPoint.dx + 9
          : endPoint.dx - 9 - textPainter.width;
      final textY = label.adjustedY - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  static void _arrangeLabels(
    List<_ChartLabel> labels,
    double height,
  ) {
    if (labels.isEmpty) return;

    labels.sort((a, b) => a.desiredY.compareTo(b.desiredY));
    const minimumGap = 34.0;
    const topPadding = 24.0;
    final bottomPadding = height - 24.0;

    var previousY = topPadding - minimumGap;
    for (final label in labels) {
      label.adjustedY = math.max(label.desiredY, previousY + minimumGap);
      previousY = label.adjustedY;
    }

    if (labels.last.adjustedY > bottomPadding) {
      final shift = labels.last.adjustedY - bottomPadding;
      for (final label in labels) {
        label.adjustedY -= shift;
      }
    }

    if (labels.first.adjustedY < topPadding) {
      final shift = topPadding - labels.first.adjustedY;
      for (final label in labels) {
        label.adjustedY += shift;
      }
    }
  }

  static String _shortLabel(String value) {
    final text = value.trim().isEmpty ? 'Lainnya' : value.trim();
    return text.length <= 18 ? text : '${text.substring(0, 15)}...';
  }

  @override
  bool shouldRepaint(covariant _DonutReportPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.categories != categories ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.labelColor != labelColor;
  }
}

class _ChartLabel {
  _ChartLabel({
    required this.category,
    required this.angle,
    required this.desiredY,
    required this.isRight,
  }) : adjustedY = desiredY;

  final _CategorySlice category;
  final double angle;
  final double desiredY;
  final bool isRight;
  double adjustedY;
}

class _CategorySlice {
  const _CategorySlice({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

enum _TransactionKind {
  income,
  expense,
}

class _ReportTransaction {
  const _ReportTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.envelopeId,
    required this.date,
  });

  final String id;
  final String title;
  final String description;
  final double amount;
  final _TransactionKind type;
  final String envelopeId;
  final DateTime date;
}

class _ReportPayload {
  const _ReportPayload({
    required this.income,
    required this.expense,
    required this.categories,
    required this.transactions,
  });

  const _ReportPayload.empty()
      : income = 0,
        expense = 0,
        categories = const <_CategorySlice>[],
        transactions = const <_ReportTransaction>[];

  final double income;
  final double expense;
  final List<_CategorySlice> categories;
  final List<_ReportTransaction> transactions;
}

class _ReportException implements Exception {
  const _ReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
