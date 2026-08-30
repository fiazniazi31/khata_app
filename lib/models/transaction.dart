class TransactionModel {
  final int? id;
  final String customerName;
  final double price;
  final String type; // 'give' (we pay/give) or 'take' (we receive/take)
  final String description;
  final DateTime date;
  final int? accountId;
  final DateTime? dueDate;

  TransactionModel({
    this.id,
    required this.customerName,
    required this.price,
    required this.type,
    this.description = '',
    required this.date,
    this.accountId,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerName': customerName,
      'price': price,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      if (accountId != null) 'accountId': accountId,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      customerName: map['customerName'] as String,
      price: (map['price'] as num).toDouble(),
      type: map['type'] as String,
      description: map['description'] ?? '',
      date: map['date'] != null 
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      accountId: map['accountId'] as int?,
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'].toString()) : null,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? customerName,
    double? price,
    String? type,
    String? description,
    DateTime? date,
    int? accountId,
    DateTime? dueDate,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      price: price ?? this.price,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
