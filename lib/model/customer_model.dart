class ModelCustomer {
  int? id;
  String name;
  String paymentPurpose;
  String phone;

  ModelCustomer(
      {this.id,
      required this.name,
      required this.paymentPurpose,
      required this.phone});

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "paymentPurpose": paymentPurpose,
        "phone": phone
      };

  factory ModelCustomer.ModelObjFromMap(Map<String, dynamic> json) =>
      ModelCustomer(
        id: json["id"],
        name: json["name"],
        paymentPurpose: json["paymentPurpose"],
        phone: json["phone"],
      );
}
