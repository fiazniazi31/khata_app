class ModelTransaction {
  int? id;
  String customerName;
  double price;
  String type;

  ModelTransaction({
    this.id,
    required this.customerName,
    required this.price,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "customerName": customerName,
        "price": price,
        "type": type,
      };

  factory ModelTransaction.ModelObjFromMap(Map<String, dynamic> json) =>
      ModelTransaction(
        id: json["id"],
        customerName: json["customerName"],
        price: json["price"],
        type: json["type"],
      );
}
