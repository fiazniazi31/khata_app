import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../providers/khata_provider.dart';
import '../../utils/expense_constants.dart';
import '../../utils/pdf_helper.dart';
import '../widgets/category_card.dart';
import '../widgets/expense_pie_chart.dart';

class ExpenseTab extends StatefulWidget {
  const ExpenseTab({super.key});

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<ExpenseTab> {
  int _selectedViewIndex = 0; // 0 for Expenses, 1 for Income

  // --- Add/Edit Sheets ---

  void _showAddExpenseSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currencySymbol = Provider.of<KhataProvider>(context, listen: false).currencySymbol;
    
    DateTime selectedDate = DateTime.now();
    String selectedCategory = ExpenseConstants.categoriesList.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setModalState(() {
                  selectedDate = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Log New Expense",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "What did you buy?",
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                        labelText: "Expense Name",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Expense name is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            currencySymbol,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        labelText: "Amount Spent",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Amount is required";
                        }
                        final numVal = double.tryParse(value);
                        if (numVal == null || numVal <= 0) {
                          return "Enter a valid amount greater than 0";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor,
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(selectedDate),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.inputDecorationTheme.fillColor,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: ExpenseConstants.categoriesList.contains(selectedCategory)
                                    ? selectedCategory
                                    : ExpenseConstants.categoriesList.first,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                items: ExpenseConstants.categoriesList
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedCategory = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final price = double.parse(amountController.text);
                        final name = titleController.text.trim();

                        final newExpense = Expense(
                          title: name,
                          amount: price,
                          date: selectedDate,
                          category: selectedCategory,
                        );

                        final provider = Provider.of<KhataProvider>(context, listen: false);
                        final success = await provider.addExpense(newExpense);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Expense recorded successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save Expense"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddIncomeSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currencySymbol = Provider.of<KhataProvider>(context, listen: false).currencySymbol;
    
    DateTime selectedDate = DateTime.now();
    String selectedCategory = IncomeConstants.categoriesList.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setModalState(() {
                  selectedDate = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Log New Income",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "Freelance project, Salary, etc.",
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        labelText: "Income Title",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Income title is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            currencySymbol,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        labelText: "Amount Received",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Amount is required";
                        }
                        final numVal = double.tryParse(value);
                        if (numVal == null || numVal <= 0) {
                          return "Enter a valid amount greater than 0";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor,
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(selectedDate),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.inputDecorationTheme.fillColor,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                items: IncomeConstants.categoriesList
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedCategory = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final amt = double.parse(amountController.text);
                        final title = titleController.text.trim();

                        final newIncome = Income(
                          title: title,
                          amount: amt,
                          date: selectedDate,
                          category: selectedCategory,
                        );

                        final provider = Provider.of<KhataProvider>(context, listen: false);
                        final success = await provider.addIncome(newIncome);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Income recorded successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save Income"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditIncomeSheet(BuildContext context, Income income) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: income.title);
    final amountController = TextEditingController(text: income.amount.toStringAsFixed(2));
    final currencySymbol = Provider.of<KhataProvider>(context, listen: false).currencySymbol;
    
    DateTime selectedDate = income.date;
    String selectedCategory = income.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setModalState(() {
                  selectedDate = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Edit Income Log",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "Income source",
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        labelText: "Income Title",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Income title is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            currencySymbol,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        labelText: "Amount Received",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Amount is required";
                        }
                        final numVal = double.tryParse(value);
                        if (numVal == null || numVal <= 0) {
                          return "Enter a valid amount";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor,
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(selectedDate),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.inputDecorationTheme.fillColor,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                items: IncomeConstants.categoriesList
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedCategory = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final amt = double.parse(amountController.text);
                        final title = titleController.text.trim();

                        final updatedIncome = income.copyWith(
                          title: title,
                          amount: amt,
                          date: selectedDate,
                          category: selectedCategory,
                        );

                        final provider = Provider.of<KhataProvider>(context, listen: false);
                        final success = await provider.updateIncome(updatedIncome);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Income updated successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save Changes"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- PDF Share Action ---

  Future<void> _shareMonthlyReport(BuildContext context, KhataProvider provider) async {
    try {
      final file = await PdfHelper.generateMonthlyReportPdf(
        selectedMonth: provider.selectedBudgetMonth,
        expenses: provider.monthlyExpenses,
        incomes: provider.monthlyIncomes,
        totalIncome: provider.totalMonthlyIncome,
        totalExpenses: provider.totalMonthlyExpenses,
        netBalance: provider.monthlyRemainingBalance,
        currency: provider.currencySymbol,
      );
      
      final monthStr = DateFormat('MMMM_yyyy').format(provider.selectedBudgetMonth);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Khata App - Income & Expense Statement - $monthStr',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating report: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickMonth(BuildContext context, KhataProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedBudgetMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      provider.setSelectedBudgetMonth(DateTime(picked.year, picked.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<KhataProvider>(
      builder: (context, provider, child) {
        final categories = provider.expenseCategories;
        final currency = provider.currencySymbol;
        final activeMonth = provider.selectedBudgetMonth;
        final monthStr = DateFormat('MMMM yyyy').format(activeMonth);

        final totalIncome = provider.totalMonthlyIncome;
        final totalExp = provider.totalMonthlyExpenses;
        final balance = provider.monthlyRemainingBalance;

        return Scaffold(
          body: Column(
            children: [
              // 1. Month Picker Controller Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      onPressed: () {
                        provider.setSelectedBudgetMonth(DateTime(activeMonth.year, activeMonth.month - 1));
                      },
                    ),
                    TextButton.icon(
                      onPressed: () => _pickMonth(context, provider),
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        monthStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      onPressed: () {
                        provider.setSelectedBudgetMonth(DateTime(activeMonth.year, activeMonth.month + 1));
                      },
                    ),
                  ],
                ),
              ),

              // 2. Budget Dynamic Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "REMAINING BALANCE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${balance >= 0 ? '+' : '-'} $currency${balance.abs().toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          // PDF Export sharing button
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.share_outlined, color: theme.primaryColor, size: 20),
                            ),
                            tooltip: "Share Report as PDF",
                            onPressed: () => _shareMonthlyReport(context, provider),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 14),
                                    SizedBox(width: 4),
                                    Text("Income", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$currency${totalIncome.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: theme.dividerColor.withOpacity(0.12)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 14),
                                    SizedBox(width: 4),
                                    Text("Expenses", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$currency${totalExp.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Custom View Index Switcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedViewIndex = 0),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedViewIndex == 0 ? theme.primaryColor : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                            ),
                            child: Text(
                              "EXPENSES",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _selectedViewIndex == 0 ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedViewIndex = 1),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedViewIndex == 1 ? theme.primaryColor : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                            ),
                            child: Text(
                              "INCOME",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _selectedViewIndex == 1 ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. View Bodies
              Expanded(
                child: IndexedStack(
                  index: _selectedViewIndex,
                  children: [
                    // --- EXPENSES SUBVIEW ---
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Donut Chart container
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "SPENDING ANALYSIS",
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  ExpenseDonutChart(
                                    categories: categories,
                                    totalAmount: totalExp,
                                    currency: currency,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Categories heading
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "CATEGORIES STATS",
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5),
                                ),
                                Icon(Icons.dashboard_customize_rounded, size: 12, color: Colors.grey),
                              ],
                            ),
                          ),

                          // Grid list of categories
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return CategoryCard(
                                category: categories[index],
                                totalExpensesSum: totalExp,
                                currency: currency,
                              );
                            },
                          ),
                          const SizedBox(height: 80), // bottom spacing for FAB clearance
                        ],
                      ),
                    ),

                    // --- INCOME SUBVIEW ---
                    Consumer<KhataProvider>(
                      builder: (context, provider, child) {
                        final list = provider.monthlyIncomes;

                        if (list.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text(
                                  "No income records for this month",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final dateStr = DateFormat('dd MMMM yyyy').format(item.date);
                            final catColor = IncomeConstants.getColor(item.category);
                            final catIcon = IncomeConstants.getIcon(item.category);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Slidable(
                                  key: ValueKey(item.id),
                                  startActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) {
                                          _showEditIncomeSheet(context, item);
                                        },
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit_outlined,
                                        label: 'Edit',
                                      ),
                                    ],
                                  ),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) {
                                          provider.deleteIncome(item.id!);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Income record deleted"), backgroundColor: Colors.orange),
                                          );
                                        },
                                        backgroundColor: const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete_outline_rounded,
                                        label: 'Delete',
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(catIcon, color: catColor, size: 20),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          "${item.category} • $dateStr",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      "+ $currency${item.amount.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_selectedViewIndex == 0) {
                _showAddExpenseSheet(context);
              } else {
                _showAddIncomeSheet(context);
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
