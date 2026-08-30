class Income {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final int? accountId;

  Income({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null && id != 0) 'id': id,
      'title': title,
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      'category': category,
      if (accountId != null) 'accountId': accountId,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
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
    );
  }

  Income copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    int? accountId,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
    );
  }
}
