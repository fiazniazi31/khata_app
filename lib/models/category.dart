import 'package:flutter/material.dart';
import '../utils/expense_constants.dart';

class ExpenseCategory {
  final String title;
  final int entries;
  final double totalAmount;
  final double budgetLimit;

  ExpenseCategory({
    required this.title,
    required this.entries,
    required this.totalAmount,
    this.budgetLimit = 0.0,
  });

  ExpenseCategory copyWith({
    String? title,
    int? entries,
    double? totalAmount,
    double? budgetLimit,
  }) {
    return ExpenseCategory(
      title: title ?? this.title,
      entries: entries ?? this.entries,
      totalAmount: totalAmount ?? this.totalAmount,
      budgetLimit: budgetLimit ?? this.budgetLimit,
    );
  }

  IconData get icon => ExpenseConstants.getIcon(title);
  Color get color => ExpenseConstants.getColor(title);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'enteries': entries, // matches original SQL column spelling 'enteries'
      'totalAmount': totalAmount.toString(),
      'budgetLimit': budgetLimit.toString(),
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      title: map['title'] as String,
      entries: map['enteries'] as int? ?? 0,
      totalAmount: map['totalAmount'] != null
          ? double.tryParse(map['totalAmount'].toString()) ?? 0.0
          : 0.0,
      budgetLimit: map['budgetLimit'] != null
          ? double.tryParse(map['budgetLimit'].toString()) ?? 0.0
          : 0.0,
    );
  }
}
