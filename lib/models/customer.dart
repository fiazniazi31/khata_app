class Customer {
  final int? id;
  final String name;
  final String paymentPurpose;
  final String phone;

  Customer({
    this.id,
    required this.name,
    required this.paymentPurpose,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'paymentPurpose': paymentPurpose,
      'phone': phone,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      paymentPurpose: map['paymentPurpose'] as String,
      phone: map['phone'] as String,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? paymentPurpose,
    String? phone,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      paymentPurpose: paymentPurpose ?? this.paymentPurpose,
      phone: phone ?? this.phone,
    );
  }
}
