import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/income.dart';
import '../models/account.dart';
import '../models/account_transfer.dart';

enum CustomerFilter { all, oweYou, youOwe }

class KhataProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ledger States
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  List<TransactionModel> _activeTransactions = [];

  // Cached balances: customerName -> netBalance (giveAmount - takeAmount)
  final Map<String, double> _customerNetBalances = {};
  final Map<String, double> _customerGiveBalances = {};
  final Map<String, double> _customerTakeBalances = {};

  // Financial aggregates (Ledger)
  double _totalOweYou = 0.0;
  double _totalYouOwe = 0.0;
  double _netBalance = 0.0;

  // Expense & Income States (v3 & v4)
  List<ExpenseCategory> _expenseCategories = [];
  List<Expense> _activeCategoryExpenses = [];
  List<Expense> _allExpenses = [];
  List<Income> _allIncomes = [];
  DateTime _selectedBudgetMonth = DateTime.now();

  // Multi-Account & Wallet States (v5)
  List<Account> _accounts = [];
  List<AccountTransfer> _accountTransfers = [];

  // Settings
  ThemeMode _themeMode = ThemeMode.light;
  String _currencySymbol = 'Rs.';
  bool _pinLockEnabled = false;
  bool _biometricLockEnabled = false;
  String _securityPin = '';

  // UI States
  CustomerFilter _activeFilter = CustomerFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;

  // Getters
  List<Customer> get customers => _filteredCustomers;
  List<Customer> get allCustomers => _allCustomers;
  List<TransactionModel> get activeTransactions => _activeTransactions;
  
  double get totalOweYou => _totalOweYou;
  double get totalYouOwe => _totalYouOwe;
  double get netBalance => _netBalance;

  // Expense & Income Getters (v4)
  DateTime get selectedBudgetMonth => _selectedBudgetMonth;
  List<Expense> get allExpenses => _allExpenses;
  List<Income> get allIncomes => _allIncomes;

  List<Expense> get monthlyExpenses {
    return _allExpenses.where((e) =>
      e.date.year == _selectedBudgetMonth.year &&
      e.date.month == _selectedBudgetMonth.month
    ).toList();
  }

  List<Income> get monthlyIncomes {
    return _allIncomes.where((i) =>
      i.date.year == _selectedBudgetMonth.year &&
      i.date.month == _selectedBudgetMonth.month
    ).toList();
  }

  double get totalMonthlyExpenses {
    return monthlyExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalMonthlyIncome {
    return monthlyIncomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthlyRemainingBalance {
    return totalMonthlyIncome - totalMonthlyExpenses;
  }

  List<ExpenseCategory> get monthlyCategories {
    final expenses = monthlyExpenses;
    final Map<String, double> categorySums = {};
    final Map<String, int> categoryCounts = {};

    for (var exp in expenses) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
      categoryCounts[exp.category] = (categoryCounts[exp.category] ?? 0) + 1;
    }

    return _expenseCategories.map((baseCat) {
      final sum = categorySums[baseCat.title] ?? 0.0;
      final count = categoryCounts[baseCat.title] ?? 0;
      return baseCat.copyWith(
        totalAmount: sum,
        entries: count,
      );
    }).toList();
  }

  List<ExpenseCategory> get expenseCategories => monthlyCategories;
  List<Expense> get activeCategoryExpenses => _activeCategoryExpenses;
  double get totalExpenses => totalMonthlyExpenses;

  List<Account> get accounts => _accounts;
  List<AccountTransfer> get accountTransfers => _accountTransfers;
  double get totalAccountBalance => _accounts.fold(0.0, (sum, a) => sum + a.balance);

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  bool get pinLockEnabled => _pinLockEnabled;
  bool get biometricLockEnabled => _biometricLockEnabled;
  String get securityPin => _securityPin;
  CustomerFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  KhataProvider() {
    _loadSettings().then((_) {
      refreshData();
    });
  }

  // --- Settings Persistence (Local JSON File) ---

  Future<File> get _settingsFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, 'app_settings.json'));
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = json.decode(content) as Map<String, dynamic>;

        _currencySymbol = map['currencySymbol'] ?? 'Rs.';
        _pinLockEnabled = map['pinLockEnabled'] ?? false;
        _biometricLockEnabled = map['biometricLockEnabled'] ?? false;
        _securityPin = map['securityPin'] ?? '';
        
        final themeStr = map['themeMode'] ?? 'light';
        _themeMode = themeStr == 'dark' 
            ? ThemeMode.dark 
            : themeStr == 'light' 
                ? ThemeMode.light 
                : ThemeMode.system;
      }
    } catch (e) {
      print("Error loading settings: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _settingsFile;
      final map = {
        'currencySymbol': _currencySymbol,
        'pinLockEnabled': _pinLockEnabled,
        'biometricLockEnabled': _biometricLockEnabled,
        'securityPin': _securityPin,
        'themeMode': _themeMode == ThemeMode.dark 
            ? 'dark' 
            : _themeMode == ThemeMode.light 
                ? 'light' 
                : 'system',
      };
      await file.writeAsString(json.encode(map));
    } catch (e) {
      print("Error saving settings: $e");
    }
  }

  // --- Configuration Mutators ---

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveSettings();
    notifyListeners();
  }

  void setCurrencySymbol(String symbol) {
    _currencySymbol = symbol;
    _saveSettings();
    notifyListeners();
  }

  void enablePinLock(String pin) {
    _pinLockEnabled = true;
    _securityPin = pin;
    _saveSettings();
    notifyListeners();
  }

  void disablePinLock() {
    _pinLockEnabled = false;
    _biometricLockEnabled = false;
    _securityPin = '';
    _saveSettings();
    notifyListeners();
  }

  void toggleBiometrics(bool enable) {
    _biometricLockEnabled = enable;
    _saveSettings();
    notifyListeners();
  }

  // --- Business Logic Functions ---

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Customers and Balances
      _allCustomers = await _dbHelper.getAllCustomers();
      
      _customerNetBalances.clear();
      _customerGiveBalances.clear();
      _customerTakeBalances.clear();

      double tempOweYou = 0.0;
      double tempYouOwe = 0.0;

      for (var customer in _allCustomers) {
        final give = await _dbHelper.getCustomerGiveAmount(customer.name);
        final take = await _dbHelper.getCustomerTakeAmount(customer.name);
        final net = give - take;

        _customerGiveBalances[customer.name] = give;
        _customerTakeBalances[customer.name] = take;
        _customerNetBalances[customer.name] = net;

        if (net > 0) {
          tempOweYou += net;
        } else if (net < 0) {
          tempYouOwe += net.abs();
        }
      }

      _totalOweYou = tempOweYou;
      _totalYouOwe = tempYouOwe;
      _netBalance = tempOweYou - tempYouOwe;

      // 2. Fetch all Expenses, Incomes, Categories, Accounts (v5)
      _allExpenses = await _dbHelper.getAllExpenses();
      _allIncomes = await _dbHelper.getAllIncomes();
      _expenseCategories = await _dbHelper.getAllCategories();
      _accounts = await _dbHelper.getAllAccounts();
      _accountTransfers = await _dbHelper.getAllTransfers();

      _applyFilters();
    } catch (e) {
      print("Error refreshing data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter & Search operations
  void setFilter(CustomerFilter filter) {
    _activeFilter = filter;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    List<Customer> results = List.from(_allCustomers);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      results = results.where((c) {
        return c.name.toLowerCase().contains(q) || 
               c.phone.contains(q) || 
               c.paymentPurpose.toLowerCase().contains(q);
      }).toList();
    }

    if (_activeFilter == CustomerFilter.oweYou) {
      results = results.where((c) {
        final net = getCustomerNetBalance(c.name);
        return net > 0;
      }).toList();
    } else if (_activeFilter == CustomerFilter.youOwe) {
      results = results.where((c) {
        final net = getCustomerNetBalance(c.name);
        return net < 0;
      }).toList();
    }

    _filteredCustomers = results;
    notifyListeners();
  }

  // --- Customer Actions ---

  Future<bool> addCustomer(Customer customer) async {
    try {
      await _dbHelper.insertCustomer(customer);
      await refreshData();
      return true;
    } catch (e) {
      print("Error adding customer: $e");
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer, {String? oldName}) async {
    try {
      if (oldName != null && oldName != customer.name) {
        final db = await _dbHelper.database;
        await db.update(
          'tran',
          {'customerName': customer.name},
          where: 'customerName = ?',
          whereArgs: [oldName],
        );
      }
      await _dbHelper.updateCustomer(customer);
      await refreshData();
      return true;
    } catch (e) {
      print("Error updating customer: $e");
      return false;
    }
  }

  Future<bool> deleteCustomer(int id, String name) async {
    try {
      await _dbHelper.deleteCustomer(id, name);
      await refreshData();
      return true;
    } catch (e) {
      print("Error deleting customer: $e");
      return false;
    }
  }

  // --- Transaction Actions ---

  Future<void> loadTransactionsForCustomer(String name) async {
    _activeTransactions = await _dbHelper.getTransactionsForCustomer(name);
    notifyListeners();
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      await _dbHelper.insertTransaction(transaction);
      await loadTransactionsForCustomer(transaction.customerName);
      await refreshData();
      return true;
    } catch (e) {
      print("Error adding transaction: $e");
      return false;
    }
  }

  Future<bool> deleteTransaction(int id, String customerName) async {
    try {
      await _dbHelper.deleteTransaction(id);
      await loadTransactionsForCustomer(customerName);
      await refreshData();
      return true;
    } catch (e) {
      print("Error deleting transaction: $e");
      return false;
    }
  }

  // --- Expense Tracking Actions (v3 & v4) ---

  void setSelectedBudgetMonth(DateTime date) {
    _selectedBudgetMonth = date;
    refreshData(); // Triggers rebuild and updates dynamic lists
  }

  Future<void> loadExpensesForCategory(String category) async {
    final list = await _dbHelper.getExpensesForCategory(category);
    _activeCategoryExpenses = list.where((e) =>
      e.date.year == _selectedBudgetMonth.year &&
      e.date.month == _selectedBudgetMonth.month
    ).toList();
    notifyListeners();
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      await _dbHelper.insertExpense(expense);
      await refreshData();
      await loadExpensesForCategory(expense.category);
      return true;
    } catch (e) {
      print("Error adding expense: $e");
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      await _dbHelper.updateExpense(expense);
      await refreshData();
      await loadExpensesForCategory(expense.category);
      return true;
    } catch (e) {
      print("Error updating expense: $e");
      return false;
    }
  }

  Future<bool> deleteExpense(int id, String category, double amount) async {
    try {
      await _dbHelper.deleteExpense(id, category, amount);
      await refreshData();
      await loadExpensesForCategory(category);
      return true;
    } catch (e) {
      print("Error deleting expense: $e");
      return false;
    }
  }

  // --- Income Tracking Actions (v4) ---

  Future<bool> addIncome(Income income) async {
    try {
      await _dbHelper.insertIncome(income);
      await refreshData();
      return true;
    } catch (e) {
      print("Error adding income: $e");
      return false;
    }
  }

  Future<bool> updateIncome(Income income) async {
    try {
      await _dbHelper.updateIncome(income);
      await refreshData();
      return true;
    } catch (e) {
      print("Error updating income: $e");
      return false;
    }
  }

  Future<bool> deleteIncome(int id) async {
    try {
      await _dbHelper.deleteIncome(id);
      await refreshData();
      return true;
    } catch (e) {
      print("Error deleting income: $e");
      return false;
    }
  }

  // --- Category Budget Actions (v5) ---

  Future<bool> updateCategoryBudget(String categoryTitle, double limit) async {
    try {
      await _dbHelper.updateCategoryBudget(categoryTitle, limit);
      await refreshData();
      return true;
    } catch (e) {
      print("Error updating category budget: $e");
      return false;
    }
  }

  // --- Account & Wallet Actions (v5) ---

  Future<bool> addAccount(Account account) async {
    try {
      await _dbHelper.insertAccount(account);
      await refreshData();
      return true;
    } catch (e) {
      print("Error adding account: $e");
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      await _dbHelper.updateAccount(account);
      await refreshData();
      return true;
    } catch (e) {
      print("Error updating account: $e");
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      await _dbHelper.deleteAccount(id);
      await refreshData();
      return true;
    } catch (e) {
      print("Error deleting account: $e");
      return false;
    }
  }

  Future<bool> transferMoney(AccountTransfer transfer) async {
    try {
      await _dbHelper.insertTransfer(transfer);
      await refreshData();
      return true;
    } catch (e) {
      print("Error transferring money: $e");
      return false;
    }
  }

  // --- Analytics & Chart Data Getters (v5) ---

  List<Map<String, dynamic>> get categoryExpenseChartData {
    final categories = monthlyCategories;
    final total = totalMonthlyExpenses;
    if (total == 0) return [];

    return categories.where((cat) => cat.totalAmount > 0).map((cat) {
      final percentage = (cat.totalAmount / total) * 100;
      return {
        'title': cat.title,
        'amount': cat.totalAmount,
        'percentage': percentage,
        'color': cat.color,
        'icon': cat.icon,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get monthlyIncomeVsExpenseData {
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthExpenses = _allExpenses.where((e) =>
        e.date.year == monthDate.year && e.date.month == monthDate.month
      ).fold(0.0, (sum, item) => sum + item.amount);

      final monthIncomes = _allIncomes.where((inc) =>
        inc.date.year == monthDate.year && inc.date.month == monthDate.month
      ).fold(0.0, (sum, item) => sum + item.amount);

      result.add({
        'date': monthDate,
        'income': monthIncomes,
        'expense': monthExpenses,
      });
    }
    return result;
  }

  // Wipe database completely (Reset)
  Future<void> wipeAllData() async {
    await _dbHelper.clearDatabase();
    await refreshData();
  }

  // Helper getters for individual customers
  double getCustomerNetBalance(String name) => _customerNetBalances[name] ?? 0.0;
  double getCustomerGiveBalance(String name) => _customerGiveBalances[name] ?? 0.0;
  double getCustomerTakeBalance(String name) => _customerTakeBalances[name] ?? 0.0;
}
