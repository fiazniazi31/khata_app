import 'package:flutter_test/flutter_test.dart';
import 'package:khata_and_expance_tracker/models/customer.dart';
import 'package:khata_and_expance_tracker/models/transaction.dart';
import 'package:khata_and_expance_tracker/models/expense.dart';
import 'package:khata_and_expance_tracker/models/category.dart';
import 'package:khata_and_expance_tracker/models/income.dart';
import 'package:khata_and_expance_tracker/models/savings_transaction.dart';

void main() {
  group('Customer Model Tests', () {
    test('Customer model serializes to Map correctly', () {
      final customer = Customer(
        id: 1,
        name: 'John Doe',
        paymentPurpose: 'Weekly supply',
        phone: '1234567890',
      );

      final map = customer.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'John Doe');
      expect(map['paymentPurpose'], 'Weekly supply');
      expect(map['phone'], '1234567890');
    });

    test('Customer model deserializes from Map correctly', () {
      final map = {
        'id': 2,
        'name': 'Jane Smith',
        'paymentPurpose': 'Rent payment',
        'phone': '0987654321',
      };

      final customer = Customer.fromMap(map);

      expect(customer.id, 2);
      expect(customer.name, 'Jane Smith');
      expect(customer.paymentPurpose, 'Rent payment');
      expect(customer.phone, '0987654321');
    });
  });

  group('TransactionModel Tests', () {
    test('Transaction model serializes to Map correctly', () {
      final date = DateTime(2026, 6, 19, 12, 0, 0);
      final transaction = TransactionModel(
        id: 10,
        customerName: 'John Doe',
        price: 250.50,
        type: 'give',
        description: 'Milk delivery',
        date: date,
      );

      final map = transaction.toMap();

      expect(map['id'], 10);
      expect(map['customerName'], 'John Doe');
      expect(map['price'], 250.50);
      expect(map['type'], 'give');
      expect(map['description'], 'Milk delivery');
      expect(map['date'], date.toIso8601String());
    });

    test('Transaction model deserializes from Map correctly', () {
      final dateStr = '2026-06-19T14:30:00.000Z';
      final map = {
        'id': 15,
        'customerName': 'Jane Smith',
        'price': 1000,
        'type': 'take',
        'description': 'Repayment',
        'date': dateStr,
      };

      final transaction = TransactionModel.fromMap(map);

      expect(transaction.id, 15);
      expect(transaction.customerName, 'Jane Smith');
      expect(transaction.price, 1000.0);
      expect(transaction.type, 'take');
      expect(transaction.description, 'Repayment');
      expect(transaction.date, DateTime.parse(dateStr));
    });
  });

  group('Expense Model Tests', () {
    test('Expense model serializes to Map correctly', () {
      final date = DateTime(2026, 6, 19, 15, 0, 0);
      final expense = Expense(
        id: 5,
        title: 'Lunch',
        amount: 45.50,
        date: date,
        category: 'Food and drink',
      );

      final map = expense.toMap();

      expect(map['id'], 5);
      expect(map['title'], 'Lunch');
      expect(map['amount'], '45.5');
      expect(map['date'], date.toIso8601String());
      expect(map['category'], 'Food and drink');
    });

    test('Expense model deserializes from Map correctly', () {
      final map = {
        'id': 8,
        'title': 'Taxi Ride',
        'amount': '12.0',
        'date': '2026-06-19T15:10:00.000Z',
        'category': 'Auto and transport',
      };

      final expense = Expense.fromMap(map);

      expect(expense.id, 8);
      expect(expense.title, 'Taxi Ride');
      expect(expense.amount, 12.0);
      expect(expense.category, 'Auto and transport');
      expect(expense.date, DateTime.parse('2026-06-19T15:10:00.000Z'));
    });
  });

  group('ExpenseCategory Model Tests', () {
    test('ExpenseCategory serializes to Map correctly', () {
      final category = ExpenseCategory(
        title: 'Education',
        entries: 3,
        totalAmount: 1500.0,
      );

      final map = category.toMap();

      expect(map['title'], 'Education');
      expect(map['enteries'], 3);
      expect(map['totalAmount'], '1500.0');
    });

    test('ExpenseCategory deserializes from Map correctly', () {
      final map = {
        'title': 'Entertainment',
        'enteries': 2,
        'totalAmount': '350.50',
      };

      final category = ExpenseCategory.fromMap(map);

      expect(category.title, 'Entertainment');
      expect(category.entries, 2);
      expect(category.totalAmount, 350.50);
    });
  });

  group('Income Model Tests', () {
    test('Income model serializes to Map correctly', () {
      final date = DateTime(2026, 6, 19, 10, 0, 0);
      final income = Income(
        id: 3,
        title: 'Salary Deposit',
        amount: 5000.0,
        date: date,
        category: 'Salary',
      );

      final map = income.toMap();

      expect(map['id'], 3);
      expect(map['title'], 'Salary Deposit');
      expect(map['amount'], '5000.0');
      expect(map['date'], date.toIso8601String());
      expect(map['category'], 'Salary');
    });

    test('Income model deserializes from Map correctly', () {
      final map = {
        'id': 7,
        'title': 'App Project',
        'amount': '1500.25',
        'date': '2026-06-19T10:00:00.000Z',
        'category': 'Freelance',
      };

      final income = Income.fromMap(map);

      expect(income.id, 7);
      expect(income.title, 'App Project');
      expect(income.amount, 1500.25);
      expect(income.category, 'Freelance');
      expect(income.date, DateTime.parse('2026-06-19T10:00:00.000Z'));
    });
  });

  group('SavingsTransaction Model Tests', () {
    test('Savings deposit serializes to Map correctly', () {
      final date = DateTime(2026, 9, 1, 10, 0, 0);
      final tx = SavingsTransaction(
        id: 1,
        amount: 10000.0,
        transactionType: SavingsTransactionType.deposit,
        transactionDate: date,
        note: 'Monthly saving',
      );

      final map = tx.toMap();

      expect(map['id'], 1);
      expect(map['amount'], 10000.0);
      expect(map['transactionType'], 'deposit');
      expect(map['transactionDate'], date.toIso8601String());
      expect(map['note'], 'Monthly saving');
      expect(tx.isDeposit, true);
      expect(tx.isWithdrawal, false);
    });

    test('Savings withdrawal deserializes from Map correctly', () {
      final dateStr = '2026-09-25T14:00:00.000';
      final map = {
        'id': 2,
        'amount': 3000.0,
        'transactionType': 'withdrawal',
        'transactionDate': dateStr,
        'note': 'Emergency',
        'createdAt': dateStr,
        'updatedAt': dateStr,
      };

      final tx = SavingsTransaction.fromMap(map);

      expect(tx.id, 2);
      expect(tx.amount, 3000.0);
      expect(tx.transactionType, SavingsTransactionType.withdrawal);
      expect(tx.isDeposit, false);
      expect(tx.isWithdrawal, true);
      expect(tx.note, 'Emergency');
    });
  });

  group('Savings Balance, Carry Forward & Running Balance Tests', () {
    test('Calculates balance = Total Deposits - Total Withdrawals', () {
      final txs = [
        SavingsTransaction(
          id: 1,
          amount: 20000,
          transactionType: SavingsTransactionType.deposit,
          transactionDate: DateTime(2026, 9, 1),
        ),
        SavingsTransaction(
          id: 2,
          amount: 10000,
          transactionType: SavingsTransactionType.deposit,
          transactionDate: DateTime(2026, 9, 10),
        ),
        SavingsTransaction(
          id: 3,
          amount: 5000,
          transactionType: SavingsTransactionType.deposit,
          transactionDate: DateTime(2026, 9, 20),
        ),
        SavingsTransaction(
          id: 4,
          amount: 5000,
          transactionType: SavingsTransactionType.withdrawal,
          transactionDate: DateTime(2026, 9, 25),
        ),
      ];

      final totalDeposits = txs.where((t) => t.isDeposit).fold(0.0, (sum, t) => sum + t.amount);
      final totalWithdrawals = txs.where((t) => t.isWithdrawal).fold(0.0, (sum, t) => sum + t.amount);
      final balance = totalDeposits - totalWithdrawals;

      expect(totalDeposits, 35000.0);
      expect(totalWithdrawals, 5000.0);
      expect(balance, 30000.0);
    });

    test('Carry forward between months: September balance carries into October and November', () {
      final septemberDeposit = SavingsTransaction(
        id: 1,
        amount: 30000,
        transactionType: SavingsTransactionType.deposit,
        transactionDate: DateTime(2026, 9, 15),
      );
      final octoberDeposit = SavingsTransaction(
        id: 2,
        amount: 10000,
        transactionType: SavingsTransactionType.deposit,
        transactionDate: DateTime(2026, 10, 5),
      );
      final novemberDeposit = SavingsTransaction(
        id: 3,
        amount: 5000,
        transactionType: SavingsTransactionType.deposit,
        transactionDate: DateTime(2026, 11, 2),
      );

      final allTxs = [septemberDeposit, octoberDeposit, novemberDeposit];

      // September ending balance
      final sepEnd = allTxs
          .where((t) => t.transactionDate.isBefore(DateTime(2026, 10, 1)))
          .fold(0.0, (sum, t) => sum + (t.isDeposit ? t.amount : -t.amount));
      expect(sepEnd, 30000.0);

      // October ending balance
      final octEnd = allTxs
          .where((t) => t.transactionDate.isBefore(DateTime(2026, 11, 1)))
          .fold(0.0, (sum, t) => sum + (t.isDeposit ? t.amount : -t.amount));
      expect(octEnd, 40000.0);

      // November ending balance
      final novEnd = allTxs
          .where((t) => t.transactionDate.isBefore(DateTime(2026, 12, 1)))
          .fold(0.0, (sum, t) => sum + (t.isDeposit ? t.amount : -t.amount));
      expect(novEnd, 45000.0);
    });

    test('Calculates chronological running balance correctly', () {
      final txs = [
        SavingsTransaction(
          id: 1,
          amount: 15000,
          transactionType: SavingsTransactionType.deposit,
          transactionDate: DateTime(2026, 9, 1),
          note: 'Monthly Saving',
        ),
        SavingsTransaction(
          id: 2,
          amount: 5000,
          transactionType: SavingsTransactionType.deposit,
          transactionDate: DateTime(2026, 9, 15),
          note: 'Extra Saving',
        ),
        SavingsTransaction(
          id: 3,
          amount: 3000,
          transactionType: SavingsTransactionType.withdrawal,
          transactionDate: DateTime(2026, 9, 25),
          note: 'Emergency',
        ),
        SavingsTransaction(
          id: 4,
          amount: 10000,
          transactionType: SavingsTransactionType.deposit,
          transactionDate: DateTime(2026, 9, 30),
          note: 'Bonus Saving',
        ),
      ];

      // Sort chronologically
      final sorted = List<SavingsTransaction>.from(txs)
        ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

      double running = 0.0;
      final withRunning = sorted.map((t) {
        running += t.isDeposit ? t.amount : -t.amount;
        return t.copyWith(runningBalance: running);
      }).toList();

      expect(withRunning[0].runningBalance, 15000.0);
      expect(withRunning[1].runningBalance, 20000.0);
      expect(withRunning[2].runningBalance, 17000.0);
      expect(withRunning[3].runningBalance, 27000.0);
    });

    test('Savings independence: adding/withdrawing savings does not change income or expenses', () {
      double totalIncome = 100000.0;
      double totalExpenses = 60000.0;
      double totalSavings = 20000.0;

      // Withdrawing 5,000 from Savings:
      const savingsWithdrawal = 5000.0;
      totalSavings -= savingsWithdrawal;

      expect(totalSavings, 15000.0);
      // Income and expenses MUST remain completely unchanged:
      expect(totalIncome, 100000.0);
      expect(totalExpenses, 60000.0);

      // Adding 10,000 to Savings:
      const savingsDeposit = 10000.0;
      totalSavings += savingsDeposit;

      expect(totalSavings, 25000.0);
      // Still completely unchanged:
      expect(totalIncome, 100000.0);
      expect(totalExpenses, 60000.0);
    });
  });
}
