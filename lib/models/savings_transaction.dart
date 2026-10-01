enum SavingsTransactionType {
  deposit,
  withdrawal;

  static SavingsTransactionType fromString(String type) {
    if (type.toLowerCase() == 'withdrawal') {
      return SavingsTransactionType.withdrawal;
    }
    return SavingsTransactionType.deposit;
  }
}

class SavingsTransaction {
  final int? id;
  final double amount;
  final SavingsTransactionType transactionType;
  final DateTime transactionDate;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Transient computed field for display and statements
  final double? runningBalance;

  SavingsTransaction({
    this.id,
    required this.amount,
    required this.transactionType,
    required this.transactionDate,
    this.note = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.runningBalance,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isDeposit => transactionType == SavingsTransactionType.deposit;
  bool get isWithdrawal => transactionType == SavingsTransactionType.withdrawal;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'transactionType': transactionType.name,
      'transactionDate': transactionDate.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavingsTransaction.fromMap(Map<String, dynamic> map) {
    return SavingsTransaction(
      id: map['id'] as int?,
      amount: map['amount'] != null
          ? (map['amount'] as num).toDouble()
          : 0.0,
      transactionType: SavingsTransactionType.fromString(
        map['transactionType'] as String? ?? 'deposit',
      ),
      transactionDate: map['transactionDate'] != null
          ? DateTime.tryParse(map['transactionDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  SavingsTransaction copyWith({
    int? id,
    double? amount,
    SavingsTransactionType? transactionType,
    DateTime? transactionDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? runningBalance,
  }) {
    return SavingsTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      runningBalance: runningBalance ?? this.runningBalance,
    );
  }
}
