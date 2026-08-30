import 'package:flutter/material.dart';

class Account {
  final int? id;
  final String name;
  final String type; // 'cash', 'bank', 'wallet', 'card'
  final double balance;
  final String accountNumber;
  final String iconName;
  final String colorHex;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.accountNumber = '',
    this.iconName = 'account_balance_wallet',
    this.colorHex = '4CAF50',
  });

  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
    String? accountNumber,
    String? iconName,
    String? colorHex,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      accountNumber: accountNumber ?? this.accountNumber,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
      'balance': balance,
      'accountNumber': accountNumber,
      'iconName': iconName,
      'colorHex': colorHex,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      accountNumber: map['accountNumber'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'account_balance_wallet',
      colorHex: map['colorHex'] as String? ?? '4CAF50',
    );
  }

  Color get color {
    try {
      return Color(int.parse('0xFF$colorHex'));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'wallet':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      case 'cash':
      default:
        return Icons.payments;
    }
  }
}
