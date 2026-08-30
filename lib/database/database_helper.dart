import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/income.dart';
import '../models/account.dart';
import '../models/account_transfer.dart';
import '../utils/expense_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('KhataApp.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Customers Table (v1)
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        paymentPurpose TEXT NOT NULL,
        phone TEXT NOT NULL
      )
    ''');

    // Transactions Table (v1 & v2 & v5)
    await db.execute('''
      CREATE TABLE tran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        price REAL NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL DEFAULT '',
        accountId INTEGER,
        dueDate TEXT
      )
    ''');

    // Category Table (v3 & v5)
    await db.execute('''
      CREATE TABLE catogeryTable (
        title TEXT UNIQUE,
        enteries INTEGER DEFAULT 0,
        totalAmount TEXT DEFAULT '0.0',
        budgetLimit TEXT DEFAULT '0.0'
      )
    ''');

    // Expense Table (v3 & v5)
    await db.execute('''
      CREATE TABLE expenseTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount TEXT,
        date TEXT,
        category TEXT,
        accountId INTEGER,
        dueDate TEXT
      )
    ''');

    // Income Table (v4 & v5)
    await db.execute('''
      CREATE TABLE incomeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount TEXT,
        date TEXT,
        category TEXT,
        accountId INTEGER
      )
    ''');

    // Accounts Table (v5)
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        accountNumber TEXT DEFAULT '',
        iconName TEXT DEFAULT 'account_balance_wallet',
        colorHex TEXT DEFAULT '4CAF50'
      )
    ''');

    // Account Transfers Table (v5)
    await db.execute('''
      CREATE TABLE accountTransfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fromAccountId INTEGER NOT NULL,
        toAccountId INTEGER NOT NULL,
        fromAccountName TEXT NOT NULL,
        toAccountName TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT DEFAULT ''
      )
    ''');

    // Pre-populate default categories & accounts
    await syncCategories(db);
    await _seedDefaultAccounts(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE tran ADD COLUMN description TEXT NOT NULL DEFAULT ''");
      } catch (e) {
        print("Upgrade column description error: $e");
      }
      try {
        await db.execute("ALTER TABLE tran ADD COLUMN date TEXT NOT NULL DEFAULT ''");
      } catch (e) {
        print("Upgrade column date error: $e");
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE catogeryTable (
            title TEXT UNIQUE,
            enteries INTEGER DEFAULT 0,
            totalAmount TEXT DEFAULT '0.0'
          )
        ''');
      } catch (e) {
        print("Create catogeryTable error: $e");
      }

      try {
        await db.execute('''
          CREATE TABLE expenseTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount TEXT,
            date TEXT,
            category TEXT
          )
        ''');
      } catch (e) {
        print("Create expenseTable error: $e");
      }

      await syncCategories(db);
    }

    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE incomeTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount TEXT,
            date TEXT,
            category TEXT
          )
        ''');
      } catch (e) {
        print("Create incomeTable error: $e");
      }
    }

    if (oldVersion < 5) {
      // Upgrade from v4 to v5
      try {
        await db.execute("ALTER TABLE catogeryTable ADD COLUMN budgetLimit TEXT DEFAULT '0.0'");
      } catch (e) {
        print("Upgrade catogeryTable budgetLimit error: $e");
      }
      try {
        await db.execute("ALTER TABLE expenseTable ADD COLUMN accountId INTEGER");
        await db.execute("ALTER TABLE expenseTable ADD COLUMN dueDate TEXT");
      } catch (e) {
        print("Upgrade expenseTable error: $e");
      }
      try {
        await db.execute("ALTER TABLE incomeTable ADD COLUMN accountId INTEGER");
      } catch (e) {
        print("Upgrade incomeTable error: $e");
      }
      try {
        await db.execute("ALTER TABLE tran ADD COLUMN accountId INTEGER");
        await db.execute("ALTER TABLE tran ADD COLUMN dueDate TEXT");
      } catch (e) {
        print("Upgrade tran error: $e");
      }
      try {
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL NOT NULL DEFAULT 0.0,
            accountNumber TEXT DEFAULT '',
            iconName TEXT DEFAULT 'account_balance_wallet',
            colorHex TEXT DEFAULT '4CAF50'
          )
        ''');
      } catch (e) {
        print("Create accounts table error: $e");
      }
      try {
        await db.execute('''
          CREATE TABLE accountTransfers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fromAccountId INTEGER NOT NULL,
            toAccountId INTEGER NOT NULL,
            fromAccountName TEXT NOT NULL,
            toAccountName TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            note TEXT DEFAULT ''
          )
        ''');
      } catch (e) {
        print("Create accountTransfers table error: $e");
      }

      await _seedDefaultAccounts(db);
    }
  }

  Future<void> _seedDefaultAccounts(Database db) async {
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM accounts');
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count == 0) {
      await db.insert('accounts', {
        'name': 'Cash in Hand',
        'type': 'cash',
        'balance': 0.0,
        'accountNumber': '',
        'iconName': 'payments',
        'colorHex': '4CAF50',
      });
      await db.insert('accounts', {
        'name': 'Bank Account',
        'type': 'bank',
        'balance': 0.0,
        'accountNumber': '',
        'iconName': 'account_balance',
        'colorHex': '2196F3',
      });
      await db.insert('accounts', {
        'name': 'Mobile Wallet',
        'type': 'wallet',
        'balance': 0.0,
        'accountNumber': '',
        'iconName': 'phone_android',
        'colorHex': 'FF9800',
      });
    }
  }

  // --- Customer CRUD ---

  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id, String name) async {
    final db = await instance.database;
    await db.delete(
      'tran',
      where: 'customerName = ?',
      whereArgs: [name],
    );
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'id DESC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // --- Transaction CRUD ---

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('tran', transaction.toMap());
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tran',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getTransactionsForCustomer(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'tran',
      where: 'customerName = ?',
      whereArgs: [name],
      orderBy: 'id DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('tran', orderBy: 'id DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // Aggregate amounts for a customer
  Future<double> getCustomerGiveAmount(String name) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(price) as total FROM tran WHERE customerName = ? AND type = 'give'",
      [name],
    );
    if (result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> getCustomerTakeAmount(String name) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(price) as total FROM tran WHERE customerName = ? AND type = 'take'",
      [name],
    );
    if (result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // --- Expense CRUD (v3) ---

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    int id = 0;
    await db.transaction((txn) async {
      id = await txn.insert(
        'expenseTable',
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Fetch current category totals
      final catQuery = await txn.query(
        'catogeryTable',
        where: 'title = ?',
        whereArgs: [expense.category],
      );

      if (catQuery.isNotEmpty) {
        final currentEntries = catQuery.first['enteries'] as int? ?? 0;
        final currentAmount = double.tryParse(catQuery.first['totalAmount']?.toString() ?? '0.0') ?? 0.0;

        await txn.update(
          'catogeryTable',
          {
            'enteries': currentEntries + 1,
            'totalAmount': (currentAmount + expense.amount).toString(),
          },
          where: 'title = ?',
          whereArgs: [expense.category],
        );
      }
    });
    return id;
  }

  Future<int> deleteExpense(int id, String category, double amount) async {
    final db = await instance.database;
    int count = 0;
    await db.transaction((txn) async {
      count = await txn.delete(
        'expenseTable',
        where: 'id = ?',
        whereArgs: [id],
      );

      final catQuery = await txn.query(
        'catogeryTable',
        where: 'title = ?',
        whereArgs: [category],
      );

      if (catQuery.isNotEmpty) {
        final currentEntries = catQuery.first['enteries'] as int? ?? 0;
        final currentAmount = double.tryParse(catQuery.first['totalAmount']?.toString() ?? '0.0') ?? 0.0;

        await txn.update(
          'catogeryTable',
          {
            'enteries': (currentEntries - 1) < 0 ? 0 : currentEntries - 1,
            'totalAmount': ((currentAmount - amount) < 0 ? 0.0 : currentAmount - amount).toString(),
          },
          where: 'title = ?',
          whereArgs: [category],
        );
      }
    });
    return count;
  }

  Future<List<Expense>> getExpensesForCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'expenseTable',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'id DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenseTable', orderBy: 'id DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<void> syncCategories([Database? dbTarget]) async {
    final db = dbTarget ?? await instance.database;

    final Map<String, String> categoryMappings = {
      'Auto and transport': 'Auto and Transport',
      'Auto and Transpoart': 'Auto and Transport',
      'Medical': 'Health & Medication',
      'Health and Medication': 'Health & Medication',
      'Home Expenses': 'Domestic Expenses',
      'Domastic Expances': 'Domestic Expenses',
      'Bills': 'Bills & Utilities',
      'Bills & Utilites': 'Bills & Utilities',
      'Food or Shopping': 'Food & Shopping',
      'Food and drink': 'Food & Shopping',
      'Food & Shooptin': 'Food & Shopping',
      'Other': 'Others',
      'Sports': 'Others',
      'Entertainment': 'Others',
      'Education': 'Others',
    };

    for (final entry in categoryMappings.entries) {
      if (entry.key != entry.value) {
        await db.execute(
          'UPDATE expenseTable SET category = ? WHERE category = ?',
          [entry.value, entry.key],
        );
      }
    }

    final existingRows = await db.query('catogeryTable');
    final existingTitles = existingRows.map((r) => r['title'] as String).toSet();

    for (final targetCat in ExpenseConstants.categoriesList) {
      if (!existingTitles.contains(targetCat)) {
        await db.insert(
          'catogeryTable',
          {
            'title': targetCat,
            'enteries': 0,
            'totalAmount': '0.0',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    final targetSet = ExpenseConstants.categoriesList.toSet();
    for (final row in existingRows) {
      final title = row['title'] as String;
      if (!targetSet.contains(title)) {
        final countResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM expenseTable WHERE category = ?',
          [title],
        );
        final count = Sqflite.firstIntValue(countResult) ?? 0;
        if (count == 0) {
          await db.delete('catogeryTable', where: 'title = ?', whereArgs: [title]);
        }
      }
    }
  }

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await instance.database;
    await syncCategories(db);
    final result = await db.query('catogeryTable');
    return result.map((json) => ExpenseCategory.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense newExpense) async {
    final db = await instance.database;
    int count = 0;
    await db.transaction((txn) async {
      // 1. Fetch old expense
      final oldList = await txn.query(
        'expenseTable',
        where: 'id = ?',
        whereArgs: [newExpense.id],
      );
      if (oldList.isEmpty) return;
      final oldExpense = Expense.fromMap(oldList.first);

      // 2. Decrement old category stats
      final oldCatQuery = await txn.query(
        'catogeryTable',
        where: 'title = ?',
        whereArgs: [oldExpense.category],
      );
      if (oldCatQuery.isNotEmpty) {
        final currentEntries = oldCatQuery.first['enteries'] as int? ?? 0;
        final currentAmount = double.tryParse(oldCatQuery.first['totalAmount']?.toString() ?? '0.0') ?? 0.0;
        await txn.update(
          'catogeryTable',
          {
            'enteries': (currentEntries - 1) < 0 ? 0 : currentEntries - 1,
            'totalAmount': ((currentAmount - oldExpense.amount) < 0 ? 0.0 : currentAmount - oldExpense.amount).toString(),
          },
          where: 'title = ?',
          whereArgs: [oldExpense.category],
        );
      }

      // 3. Update expense in table
      count = await txn.update(
        'expenseTable',
        newExpense.toMap(),
        where: 'id = ?',
        whereArgs: [newExpense.id],
      );

      // 4. Increment new category stats
      final newCatQuery = await txn.query(
        'catogeryTable',
        where: 'title = ?',
        whereArgs: [newExpense.category],
      );
      if (newCatQuery.isNotEmpty) {
        final currentEntries = newCatQuery.first['enteries'] as int? ?? 0;
        final currentAmount = double.tryParse(newCatQuery.first['totalAmount']?.toString() ?? '0.0') ?? 0.0;
        await txn.update(
          'catogeryTable',
          {
            'enteries': currentEntries + 1,
            'totalAmount': (currentAmount + newExpense.amount).toString(),
          },
          where: 'title = ?',
          whereArgs: [newExpense.category],
        );
      }
    });
    return count;
  }

  // --- Income CRUD (v4) ---

  Future<int> insertIncome(Income income) async {
    final db = await instance.database;
    return await db.insert(
      'incomeTable',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateIncome(Income income) async {
    final db = await instance.database;
    return await db.update(
      'incomeTable',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await instance.database;
    return await db.delete(
      'incomeTable',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await instance.database;
    final result = await db.query('incomeTable', orderBy: 'id DESC');
    return result.map((json) => Income.fromMap(json)).toList();
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    try {
      await db.delete('customers');
    } catch (_) {}
    try {
      await db.delete('tran');
    } catch (_) {}
    try {
      await db.delete('expenseTable');
    } catch (_) {}
    try {
      await db.delete('incomeTable');
    } catch (_) {}
    try {
      await db.update('catogeryTable', {
        'enteries': 0,
        'totalAmount': '0.0',
      });
    } catch (_) {}
  }

  // --- Accounts CRUD (v5) ---

  Future<int> insertAccount(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts', orderBy: 'id ASC');
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<Account?> getAccountById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Account.fromMap(result.first);
    }
    return null;
  }

  // --- Account Transfer CRUD (v5) ---

  Future<int> insertTransfer(AccountTransfer transfer) async {
    final db = await instance.database;
    int transferId = 0;
    await db.transaction((txn) async {
      transferId = await txn.insert('accountTransfers', transfer.toMap());

      // Deduct from sender account
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [transfer.amount, transfer.fromAccountId],
      );

      // Add to receiver account
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [transfer.amount, transfer.toAccountId],
      );
    });
    return transferId;
  }

  Future<List<AccountTransfer>> getAllTransfers() async {
    final db = await instance.database;
    final result = await db.query('accountTransfers', orderBy: 'id DESC');
    return result.map((json) => AccountTransfer.fromMap(json)).toList();
  }

  // --- Category Budget Update (v5) ---

  Future<int> updateCategoryBudget(String title, double budgetLimit) async {
    final db = await instance.database;
    return await db.update(
      'catogeryTable',
      {'budgetLimit': budgetLimit.toString()},
      where: 'title = ?',
      whereArgs: [title],
    );
  }

  // Backup restore helpers
  Future<void> insertCategoryRaw(Map<String, dynamic> map) async {
    final db = await instance.database;
    await db.insert('catogeryTable', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertExpenseRaw(Map<String, dynamic> map) async {
    final db = await instance.database;
    await db.insert('expenseTable', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertIncomeRaw(Map<String, dynamic> map) async {
    final db = await instance.database;
    await db.insert('incomeTable', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTransferRaw(Map<String, dynamic> map) async {
    final db = await instance.database;
    await db.insert('accountTransfers', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
