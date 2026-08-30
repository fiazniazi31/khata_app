class Expense {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final int? accountId;
  final DateTime? dueDate;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.accountId,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null && id != 0) 'id': id,
      'title': title,
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      'category': category,
      if (accountId != null) 'accountId': accountId,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] != null
          ? double.tryParse(map['amount'].toString()) ?? 0.0
          : 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: map['category'] as String,
      accountId: map['accountId'] as int?,
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'].toString()) : null,
    );
  }

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    int? accountId,
    DateTime? dueDate,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
