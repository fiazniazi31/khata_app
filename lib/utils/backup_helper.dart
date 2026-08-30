import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class BackupHelper {
  static Future<String> exportBackupDataJson() async {
    final db = DatabaseHelper.instance;
    final customers = await db.getAllCustomers();
    final transactions = await db.getAllTransactions();
    final expenses = await db.getAllExpenses();
    final categories = await db.getAllCategories();
    final incomes = await db.getAllIncomes();
    final accounts = await db.getAllAccounts();
    final transfers = await db.getAllTransfers();

    final backupData = {
      'backupVersion': 5,
      'timestamp': DateTime.now().toIso8601String(),
      'customers': customers.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'incomes': incomes.map((i) => i.toMap()).toList(),
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'transfers': transfers.map((tr) => tr.toMap()).toList(),
    };

    return json.encode(backupData);
  }

  static Future<File?> exportBackup() async {
    try {
      final jsonString = await exportBackupDataJson();
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, 'khata_backup_${DateTime.now().millisecondsSinceEpoch}.json'));
      await file.writeAsString(jsonString);
      return file;
    } catch (e) {
      print("Export backup error: $e");
      return null;
    }
  }

  static Future<bool> restoreBackupFromJsonString(String jsonString) async {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;

      final customersData = map['customers'] as List<dynamic>? ?? [];
      final transactionsData = map['transactions'] as List<dynamic>? ?? [];
      final expensesData = map['expenses'] as List<dynamic>? ?? [];
      final categoriesData = map['categories'] as List<dynamic>? ?? [];
      final incomesData = map['incomes'] as List<dynamic>? ?? [];
      final accountsData = map['accounts'] as List<dynamic>? ?? [];

      final db = DatabaseHelper.instance;

      // Wipe current DB
      await db.clearDatabase();

      // Insert customers
      for (var cMap in customersData) {
        final Map<String, dynamic> cleanCustomer = Map<String, dynamic>.from(cMap as Map);
        await db.insertCustomer(Customer.fromMap(cleanCustomer));
      }

      // Insert transactions
      for (var tMap in transactionsData) {
        final Map<String, dynamic> cleanTransaction = Map<String, dynamic>.from(tMap as Map);
        await db.insertTransaction(TransactionModel.fromMap(cleanTransaction));
      }

      // Insert categories
      for (var catMap in categoriesData) {
        final Map<String, dynamic> cleanCategory = Map<String, dynamic>.from(catMap as Map);
        await db.insertCategoryRaw(cleanCategory);
      }

      // Insert expenses
      for (var expMap in expensesData) {
        final Map<String, dynamic> cleanExpense = Map<String, dynamic>.from(expMap as Map);
        await db.insertExpenseRaw(cleanExpense);
      }

      // Insert incomes
      for (var incMap in incomesData) {
        final Map<String, dynamic> cleanIncome = Map<String, dynamic>.from(incMap as Map);
        await db.insertIncomeRaw(cleanIncome);
      }

      // Insert accounts
      for (var accMap in accountsData) {
        final Map<String, dynamic> cleanAccount = Map<String, dynamic>.from(accMap as Map);
        await db.insertAccount(Account.fromMap(cleanAccount));
      }

      // Insert account transfers
      final transfersData = map['transfers'] as List<dynamic>? ?? [];
      for (var trMap in transfersData) {
        final Map<String, dynamic> cleanTransfer = Map<String, dynamic>.from(trMap as Map);
        await db.insertTransferRaw(cleanTransfer);
      }

      return true;
    } catch (e) {
      print("Restore backup from JSON error: $e");
      return false;
    }
  }

  static Future<bool> importBackup(File file) async {
    try {
      final jsonString = await file.readAsString();
      return await restoreBackupFromJsonString(jsonString);
    } catch (e) {
      print("Import backup error: $e");
      return false;
    }
  }
}
