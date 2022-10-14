import 'package:khata_app/model/customer_model.dart';
import 'package:khata_app/model/transaction_model.dart';
import 'package:sqflite/sqflite.dart';
import "package:path/path.dart" as p;

final String databaseName = "KhataApp.db";

final String columnID = "id";
final String columnName = "name";
final String columnPaymentPurpose = "paymentPurpose";
final String columnPhone = "phone";
final String columnCustomerName = "customerName";
final String columnPrice = "price";
final String columnType = "type";

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = await createDB();
    }
    return _database!;
  }

  static DatabaseService? _databaseSer;
  DatabaseService._createInstance();

  factory DatabaseService() {
    if (_databaseSer == null) {
      _databaseSer = DatabaseService._createInstance();
    }
    return _databaseSer!;
  }

  Future<Database> createDB() async {
    try {
      var databasePath = await getDatabasesPath();
      String path = p.join(databasePath, databaseName);
      Database database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        await db.execute(''' 
          CREATE TABLE customers (
            $columnID INTEGER PRIMARY KEY autoincrement,
            $columnName TEXT NOT NULL,
            $columnPaymentPurpose TEXT NOT NULL,
            $columnPhone TEXT NOT NULL
          )
         ''');
        await db.execute(''' 
          CREATE TABLE tran(
            $columnID INTEGER PRIMARY KEY autoincrement,
            $columnCustomerName TEXT NOT NULL,
            $columnPrice REAL NOT NULL,
            $columnType TEXT NOT NULL
          )
         ''');
        // await db.execute('''
        //   CREATE TABLE transaction (
        //     $columnID INTEGER PRIMARY KEY autoincrement,
        //     $columnCustomerId TEXT NOT NULL,
        //     $columnPrice TEXT NOT NULL,
        //     $columnType TEXT NOT NULL
        //     )
        //  ''');
      });
      return database;
    } catch (e) {
      print("Database creation ERROR${e.toString()}");
      return null!;
    }
  }

  Future<bool> AddCustomer(ModelCustomer modelCustomer) async {
    try {
      Database db = await this.database;
      var res = await db.insert("customers", modelCustomer.toMap());
      print("Database add result ${res}");
      return true;
    } catch (e) {
      print("Database add data ERROR${e.toString()}");
      return false;
    }
  }

  Future<bool> DeleteNoteByID(id) async {
    try {
      Database db = await this.database;
      var res = await db.delete("customers", where: "$columnID=?", whereArgs: [
        id,
      ]);
      return true;
    } catch (e) {
      print("Database delete ERROR${e.toString()}");
      return false;
    }
  }

  Future<List<ModelCustomer>> GetAllCustomers() async {
    List<ModelCustomer> Notes_list = [];
    try {
      Database db = await this.database;
      List<Map<String, dynamic>> res =
          await db.query("customers", orderBy: "$columnID DESC");
      if (res.length > 0) {
        for (int i = 0; i < res.length; i++) {
          ModelCustomer modelCustomer = ModelCustomer.ModelObjFromMap(res[i]);
          Notes_list.add(modelCustomer);
        }
      }
      return Notes_list;
    } catch (e) {
      print("Database view ERROR${e.toString()}");
      return Notes_list;
    }
  }

  Future<bool> AddTransaction(ModelTransaction modelTransaction) async {
    try {
      Database db = await this.database;
      var res = await db.insert("tran", modelTransaction.toMap());
      print("Database add result ${res}");
      return true;
    } catch (e) {
      print("Database add data ERROR${e.toString()}");
      return false;
    }
  }

  Future<List<ModelTransaction>> GetCustomersTransaction(name) async {
    List<ModelTransaction> Tran_list = [];
    try {
      Database db = await this.database;
      List<Map<String, dynamic>> res = await db.query("tran",
          where: "$columnCustomerName =?",
          whereArgs: [name],
          orderBy: "$columnID DESC");
      if (res.length > 0) {
        for (int i = 0; i < res.length; i++) {
          ModelTransaction modelTransaction =
              ModelTransaction.ModelObjFromMap(res[i]);
          Tran_list.add(modelTransaction);
        }
      }
      return Tran_list;
    } catch (e) {
      print("Database view ERROR${e.toString()}");
      return Tran_list;
    }
  }

  Future<double> GetTransactionGiveAmount(name) async {
    List<ModelTransaction> Tran_list = [];
    try {
      Database db = await this.database;
      double totalGive = 0;
      double totalTake = 0;

      List<Map<String, dynamic>> res = await db.query("tran",
          where: "$columnCustomerName =?",
          whereArgs: [name],
          orderBy: "$columnID DESC");
      if (res.length > 0) {
        for (int i = 0; i < res.length; i++) {
          ModelTransaction modelTransaction =
              ModelTransaction.ModelObjFromMap(res[i]);

          if (modelTransaction.type == "give") {
            totalTake = totalTake + modelTransaction.price;
          }
        }
      }

      return totalTake;
    } catch (e) {
      print("Database view ERROR${e.toString()}");
      return 0;
    }
  }

  Future<double> GetTransactionTakeAmount(name) async {
    List<ModelTransaction> Tran_list = [];
    try {
      Database db = await this.database;
      double totalGive = 0;
      double totalTake = 0;

      List<Map<String, dynamic>> res = await db.query("tran",
          where: "$columnCustomerName =?",
          whereArgs: [name],
          orderBy: "$columnID DESC");
      if (res.length > 0) {
        for (int i = 0; i < res.length; i++) {
          ModelTransaction modelTransaction =
              ModelTransaction.ModelObjFromMap(res[i]);

          if (modelTransaction.type == "take") {
            totalTake = totalTake + modelTransaction.price;
          }
        }
      }

      return totalTake;
    } catch (e) {
      print("Database view ERROR${e.toString()}");
      return 0;
    }
  }
}
