import 'package:amplopku/core/utils/icon_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  income,
  expense,
}

class TransactionModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String envelopeId;
  final String icon;
  final TransactionType type;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.envelopeId,
    required this.icon,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    final title = (data['title'] ?? '').toString();

    final rawDate = data['date'];

    DateTime transactionDate;

    if (rawDate is Timestamp) {
      transactionDate = rawDate.toDate();
    } else {
      transactionDate = DateTime.now();
    }

    final savedIcon = (data['icon'] ?? '').toString();

    return TransactionModel(
      id: id,
      title: title,
      description: (data['description'] ?? '').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      envelopeId: (data['envelopeId'] ?? '').toString(),
      date: transactionDate,
      type: type,
      icon: savedIcon.isNotEmpty
          ? savedIcon
          : IconHelper.detectIconName(
              title,
              isIncome: type == TransactionType.income,
            ),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'amount': amount,
      'envelopeId': envelopeId,
      'icon': icon,
      'date': Timestamp.fromDate(date),
      'type': type == TransactionType.income ? 'income' : 'expense',
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}