import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EnvelopeModel {
  final String id;
  final String nama;
  final double budget;
  final double balance;
  final double spent;
  final double percentage;
  final int color;
  final String icon;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const EnvelopeModel({
    required this.id,
    required this.nama,
    required this.budget,
    required this.balance,
    required this.spent,
    required this.percentage,
    required this.color,
    required this.icon,
    this.createdAt,
    this.updatedAt,
  });

  /// Persentase penggunaan amplop dari 0.0 sampai 1.0.
  double get progress {
    if (budget <= 0) {
      return 0.0;
    }

    return (spent / budget).clamp(0.0, 1.0).toDouble();
  }

  /// Sisa saldo amplop.
  double get remaining {
    return balance;
  }

  /// Mengubah nilai integer warna Firestore menjadi Color Flutter.
  Color get envelopeColor {
    return Color(color);
  }

  factory EnvelopeModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final dynamic createdAtValue = data['createdAt'];
    final dynamic updatedAtValue = data['updatedAt'];
    final dynamic colorValue = data['color'];

    return EnvelopeModel(
      id: id,
      nama: (data['nama'] ?? '').toString(),
      budget: _toDouble(data['budget']),
      balance: _toDouble(data['balance']),
      spent: _toDouble(data['spent']),
      percentage: _toDouble(data['percentage']),
      color: colorValue is num
          ? colorValue.toInt()
          : Colors.blue.toARGB32(),
      icon: (data['icon'] ?? 'wallet').toString(),
      createdAt: createdAtValue is Timestamp
          ? createdAtValue
          : null,
      updatedAt: updatedAtValue is Timestamp
          ? updatedAtValue
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nama': nama,
      'budget': budget,
      'balance': balance,
      'spent': spent,
      'percentage': percentage,
      'color': color,
      'icon': icon,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  EnvelopeModel copyWith({
    String? id,
    String? nama,
    double? budget,
    double? balance,
    double? spent,
    double? percentage,
    int? color,
    String? icon,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return EnvelopeModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      budget: budget ?? this.budget,
      balance: balance ?? this.balance,
      spent: spent ?? this.spent,
      percentage: percentage ?? this.percentage,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }
}