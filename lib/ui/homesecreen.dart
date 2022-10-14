import 'dart:async';

import "package:flutter/material.dart";
import 'package:khata_app/database/database_service.dart';
import 'package:khata_app/ui/customerDetail.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'addPage.dart';

class HomeSecreen extends StatefulWidget {
  const HomeSecreen({super.key});

  @override
  State<HomeSecreen> createState() => _HomeSecreenState();
}

class _HomeSecreenState extends State<HomeSecreen> {
  DatabaseService db = DatabaseService();

  get doNothing => null;

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
      appBar: AppBar(
        centerTitle: true, title: Text("Khata App"),
        // actions: [
        //   TextButton.icon(
        //       onPressed: () {},
        //       icon: Icon(Icons.logout),
        //       label: Text("Log out"))
        // ],
      ),
      body: Container(
        margin: EdgeInsets.all(10),
        child: FutureBuilder(
            future: db.GetAllCustomers(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CustomerDetail(snapshot.data[index])));
                        },
                        child: Column(children: [
                          Slidable(
                            key: const ValueKey(0),
                            startActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              dismissible: DismissiblePane(onDismissed: () {
                                db.DeleteNoteByID(snapshot.data[index].id);
                              }),
                              children: [
                                SlidableAction(
                                  onPressed: doNothing,
                                  backgroundColor: Color(0xFFFE4A49),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete Customer',
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              title: Text(
                                snapshot.data[index].name.toString(),
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                snapshot.data[index].phone.toString(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          )
                        ]),
                      );
                    });
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AddPage()));
        },
        tooltip: "Add Customer",
        child: const Icon(Icons.person_add_alt_rounded),
      ),
    );
  }
}
