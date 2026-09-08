import 'package:flutter/material.dart';

class EnvelopeData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double percentage;
  final double budget;
  final double spent;

  const EnvelopeData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.percentage,
    required this.budget,
    required this.spent,
  });

  double get remaining => budget - spent;
  double get progress => budget <= 0 ? 0 : (spent / budget).clamp(0.0, 1.0);

  EnvelopeData copyWith({
    String? name,
    IconData? icon,
    Color? color,
    double? percentage,
    double? budget,
    double? spent,
  }) {
    return EnvelopeData(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      percentage: percentage ?? this.percentage,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
    );
  }
}

class TransactionData {
  final String id;
  final String title;
  final String note;
  final double amount;
  final String type;
  final String envelopeId;
  final DateTime date;

  const TransactionData({
    required this.id,
    required this.title,
    required this.note,
    required this.amount,
    required this.type,
    required this.envelopeId,
    required this.date,
  });
}

class FinanceSnapshot {
  final double income;
  final int salaryDate;
  final List<EnvelopeData> envelopes;
  final List<TransactionData> transactions;

  const FinanceSnapshot({
    required this.income,
    required this.salaryDate,
    required this.envelopes,
    required this.transactions,
  });

  double get totalExpense => transactions
      .where((item) => item.type == 'expense')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalIncome => income + transactions
      .where((item) => item.type == 'income')
      .fold(0, (sum, item) => sum + item.amount);

  double get totalRemaining => envelopes.fold(0, (sum, item) => sum + item.remaining);

  FinanceSnapshot copyWith({
    double? income,
    int? salaryDate,
    List<EnvelopeData>? envelopes,
    List<TransactionData>? transactions,
  }) {
    return FinanceSnapshot(
      income: income ?? this.income,
      salaryDate: salaryDate ?? this.salaryDate,
      envelopes: envelopes ?? this.envelopes,
      transactions: transactions ?? this.transactions,
    );
  }
}

class FinanceStore {
  FinanceStore._();

  static final ValueNotifier<FinanceSnapshot> notifier = ValueNotifier<FinanceSnapshot>(
    FinanceSnapshot(
      income: 5000000,
      salaryDate: 25,
      envelopes: const [
        EnvelopeData(id: 'needs', name: 'Kebutuhan', icon: Icons.shopping_bag, color: Color(0xFFEF4444), percentage: 50, budget: 2500000, spent: 350000),
        EnvelopeData(id: 'wants', name: 'Keinginan', icon: Icons.coffee, color: Color(0xFFF97316), percentage: 30, budget: 1500000, spent: 225000),
        EnvelopeData(id: 'savings', name: 'Tabungan', icon: Icons.savings, color: Color(0xFF3B82F6), percentage: 20, budget: 1000000, spent: 0),
      ],
      transactions: [
        TransactionData(id: 't1', title: 'Makan siang', note: 'Kebutuhan harian', amount: 35000, type: 'expense', envelopeId: 'needs', date: DateTime.now()),
        TransactionData(id: 't2', title: 'Kopi', note: 'Self reward', amount: 25000, type: 'expense', envelopeId: 'wants', date: DateTime.now().subtract(const Duration(days: 1))),
        TransactionData(id: 't3', title: 'Freelance', note: 'Pendapatan tambahan', amount: 500000, type: 'income', envelopeId: 'savings', date: DateTime.now().subtract(const Duration(days: 2))),
      ],
    ),
  );

  static FinanceSnapshot get value => notifier.value;

  static void setIncome(double income, int salaryDate) {
    final envelopes = value.envelopes
        .map((item) => item.copyWith(budget: income * item.percentage / 100))
        .toList();
    notifier.value = value.copyWith(income: income, salaryDate: salaryDate, envelopes: envelopes);
  }

  static void setEnvelopePercentages(double needs, double wants, double savings) {
    final percentages = {'needs': needs, 'wants': wants, 'savings': savings};
    final envelopes = value.envelopes.map((item) {
      final percent = percentages[item.id] ?? item.percentage;
      return item.copyWith(percentage: percent, budget: value.income * percent / 100);
    }).toList();
    notifier.value = value.copyWith(envelopes: envelopes);
  }

  static void addTransaction(TransactionData data) {
    final envelopes = value.envelopes.map((envelope) {
      if (envelope.id != data.envelopeId || data.type != 'expense') return envelope;
      return envelope.copyWith(spent: envelope.spent + data.amount);
    }).toList();
    notifier.value = value.copyWith(
      envelopes: envelopes,
      transactions: [data, ...value.transactions],
    );
  }

  static EnvelopeData envelopeById(String id) {
    return value.envelopes.firstWhere(
      (item) => item.id == id,
      orElse: () => value.envelopes.first,
    );
  }
}
