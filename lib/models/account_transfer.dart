class AccountTransfer {
  final int? id;
  final int fromAccountId;
  final int toAccountId;
  final String fromAccountName;
  final String toAccountName;
  final double amount;
  final DateTime date;
  final String note;

  AccountTransfer({
    this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.fromAccountName,
    required this.toAccountName,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'fromAccountName': fromAccountName,
      'toAccountName': toAccountName,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AccountTransfer.fromMap(Map<String, dynamic> map) {
    return AccountTransfer(
      id: map['id'] as int?,
      fromAccountId: map['fromAccountId'] as int,
      toAccountId: map['toAccountId'] as int,
      fromAccountName: map['fromAccountName'] as String? ?? '',
      toAccountName: map['toAccountName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }
}
