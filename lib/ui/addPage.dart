import 'package:flutter/material.dart';
import 'package:khata_app/database/database_service.dart';
import 'package:khata_app/model/customer_model.dart';
import 'package:khata_app/ui/homesecreen.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController nameControler = TextEditingController();
  TextEditingController paymentPurposeControler = TextEditingController();
  TextEditingController phoneControler = TextEditingController();

  DatabaseService db = DatabaseService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      db.createDB();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Add Customer")),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: nameControler,
                decoration: InputDecoration(
                    hintText: "Enter Name", border: OutlineInputBorder()),
              ),
              SizedBox(
                height: 30,
              ),
              TextField(
                controller: paymentPurposeControler,
                decoration: InputDecoration(
                    hintText: "Payment purpose", border: OutlineInputBorder()),
              ),
              SizedBox(
                height: 30,
              ),
              TextField(
                controller: phoneControler,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    hintText: "Phone No", border: OutlineInputBorder()),
              ),
              SizedBox(
                height: 30,
              ),
              ElevatedButton(
                  onPressed: () async {
                    ModelCustomer modelCustomer = ModelCustomer(
                        name: nameControler.text,
                        paymentPurpose: paymentPurposeControler.text,
                        phone: phoneControler.text);
                    if (nameControler.text != "" &&
                        paymentPurposeControler.text != "" &&
                        phoneControler.text != "") {
                      await db.AddCustomer(modelCustomer).then((bool isAdded) {
                        if (isAdded == true) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Customer added successfully"),
                            backgroundColor: Colors.green,
                          ));
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeSecreen()));

                          print("Add successfullu");
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Customer not added"),
                            backgroundColor: Colors.red,
                          ));
                          print("Not addeed");
                        }
                      });
                    }
                  },
                  child: Text("Save Cusotmer"))
            ],
          ),
        ),
      ),
    );
  }
}
