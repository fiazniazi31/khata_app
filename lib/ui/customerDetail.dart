import 'package:flutter/material.dart';
import 'package:khata_app/database/database_service.dart';
import 'package:khata_app/model/customer_model.dart';
import 'package:khata_app/model/transaction_model.dart';

import 'homesecreen.dart';

class CustomerDetail extends StatefulWidget {
  ModelCustomer modelCustomer;
  CustomerDetail(this.modelCustomer);

  @override
  State<CustomerDetail> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<CustomerDetail> {
  TextEditingController priceControler = TextEditingController();

  DatabaseService db = DatabaseService();
  double? total;
  double? giveAm;
  double? takeAm;
  // double? remaningAmont;
  getAmount() async {
    final giveAmount =
        await db.GetTransactionGiveAmount(widget.modelCustomer.name);
    final takeAmount =
        await db.GetTransactionTakeAmount(widget.modelCustomer.name);
    setState(() {
      total = giveAmount - takeAmount;
      takeAm = takeAmount;
      giveAm = giveAmount;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAmount();
  }

  Future openDialogGiveMoney() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Enter Amount give to ${widget.modelCustomer.name}",
            style: TextStyle(color: Colors.orange),
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: priceControler,
            decoration: InputDecoration(
                hintText: "Enter Amount",
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(width: 1.3, color: Colors.orange))),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Close")),
            TextButton(
                onPressed: () async {
                  ModelTransaction modelTransaction = ModelTransaction(
                      customerName: widget.modelCustomer.name,
                      price: double.parse(priceControler.text),
                      type: "give");
                  if (priceControler.text != "") {
                    await db.AddTransaction(modelTransaction)
                        .then((bool isAdded) {
                      if (isAdded == true) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Price added successfully"),
                          backgroundColor: Colors.green,
                        ));
                        Navigator.pop(context);
                        Navigator.pop(context);

                        print("Add successfullu");
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Data not added"),
                      backgroundColor: Colors.red,
                    ));
                    print("Not addeed");
                  }
                },
                child: Text("Submit"))
          ],
        ),
      );

  Future openDialogTakeMoney() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Enter Amount take from ${widget.modelCustomer.name}",
            style: TextStyle(color: Colors.orange),
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: priceControler,
            decoration: InputDecoration(
                hintText: "Enter Amount",
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(width: 1.3, color: Colors.orange))),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Close")),
            TextButton(
                onPressed: () async {
                  ModelTransaction modelTransaction = ModelTransaction(
                      customerName: widget.modelCustomer.name,
                      price: double.parse(priceControler.text),
                      type: "take");
                  if (priceControler.text != "") {
                    await db.AddTransaction(modelTransaction)
                        .then((bool isAdded) {
                      if (isAdded == true) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Price added successfully"),
                          backgroundColor: Colors.green,
                        ));
                        Navigator.pop(context);
                        Navigator.pop(context);
                        print("Add successfullu");
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Data not added"),
                          backgroundColor: Colors.red,
                        ));
                        print("Not addeed");
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Please Enter the amount!"),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
                child: Text("Submit")),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: Text(widget.modelCustomer.name + " Detail"),
          actions: [
            TextButton.icon(
              onPressed: () {
                openDialogTakeMoney();
              },
              label: Text("Take"),
              icon: Icon(Icons.attach_money),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
            TextButton.icon(
              onPressed: () {
                openDialogGiveMoney();
              },
              label: Text("Give"),
              icon: Icon(Icons.attach_money),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
          ]),
      body: SingleChildScrollView(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text(
            //     "Total Amount taken from ${widget.modelCustomer.name} is ${takeAm}"),
            // Text(
            //     "Total Amount Given to ${widget.modelCustomer.name} is ${giveAm}"),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              trailing: Icon(
                Icons.download_rounded,
                color: Colors.green,
              ),
              title: Text(
                "Taken Amount",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              subtitle: Text(
                "Total Amount taken from ${widget.modelCustomer.name} is ${takeAm}",
                style: TextStyle(color: Colors.green),
              ),
            ),
            ListTile(
              trailing: Icon(
                Icons.upload_rounded,
                color: Colors.red,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              title: Text(
                "Given Amount",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              subtitle: Text(
                "Total Amount Given to ${widget.modelCustomer.name} is ${giveAm}",
                style: TextStyle(color: Colors.red),
              ),
            ),

            // if (total! > 0)
            //   Text(
            //       "Total Amount taken from ${widget.modelCustomer.name} is ${total}")
            // else
            //   Text(
            //       "Total Amount given to ${widget.modelCustomer.name} is ${total!.abs()}"),
            FutureBuilder(
                future: db.GetCustomersTransaction(widget.modelCustomer.name),
                // initialData: InitialData,
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              title: Text(
                                "Rs." + snapshot.data[index].price.toString(),
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: snapshot.data[index].type == "take"
                                        ? Colors.green
                                        : Colors.red),
                              ),
                              subtitle: Text(
                                snapshot.data[index].type.toString(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                    // fontSize: 20,
                                    // fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                          );
                        });
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ],
        ),
      ),
    );
  }
}
