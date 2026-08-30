import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../providers/khata_provider.dart';
import '../../utils/expense_constants.dart';

class CategoryExpensesScreen extends StatefulWidget {
  final ExpenseCategory category;

  const CategoryExpensesScreen({super.key, required this.category});

  @override
  State<CategoryExpensesScreen> createState() => _CategoryExpensesScreenState();
}

class _CategoryExpensesScreenState extends State<CategoryExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KhataProvider>(context, listen: false)
          .loadExpensesForCategory(widget.category.title);
    });
  }

  void _showAddExpenseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currencySymbol = Provider.of<KhataProvider>(context, listen: false).currencySymbol;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setDialogState(() {
                  selectedDate = picked;
                });
              }
            }

            return AlertDialog(
              title: Text(
                "Add to ${widget.category.title}",
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "What did you spend on?",
                        labelText: "Expense Name",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Expense name is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        prefixIcon: Container(
                          width: 44,
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
                          return "Enter a valid amount";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy').format(selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final price = double.parse(amountController.text);
                    final name = titleController.text.trim();

                    final newExpense = Expense(
                      title: name,
                      amount: price,
                      date: selectedDate,
                      category: widget.category.title,
                    );

                    final provider = Provider.of<KhataProvider>(context, listen: false);
                    final success = await provider.addExpense(newExpense);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Expense saved successfully"), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditExpenseDialog(BuildContext context, Expense item) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: item.title);
    final amountController = TextEditingController(text: item.amount.toStringAsFixed(2));
    final currencySymbol = Provider.of<KhataProvider>(context, listen: false).currencySymbol;
    DateTime selectedDate = item.date;
    String selectedCategory = item.category;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setDialogState(() {
                  selectedDate = picked;
                });
              }
            }

            return AlertDialog(
              title: Text(
                "Edit Expense",
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "What did you spend on?",
                        labelText: "Expense Name",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Expense name is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        prefixIcon: Container(
                          width: 44,
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
                          return "Enter a valid amount";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ExpenseConstants.categoriesList.contains(selectedCategory)
                          ? selectedCategory
                          : ExpenseConstants.categoriesList.first,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: ExpenseConstants.categoriesList
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy').format(selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final price = double.parse(amountController.text);
                    final name = titleController.text.trim();

                    final updatedExpense = item.copyWith(
                      title: name,
                      amount: price,
                      date: selectedDate,
                      category: selectedCategory,
                    );

                    final provider = Provider.of<KhataProvider>(context, listen: false);
                    final success = await provider.updateExpense(updatedExpense);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Expense updated successfully"), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<KhataProvider>(
      builder: (context, provider, child) {
        final list = provider.activeCategoryExpenses;
        final currency = provider.currencySymbol;
        
        // Find fresh category stats from updated categories list
        final freshCat = provider.expenseCategories.firstWhere(
          (c) => c.title == widget.category.title,
          orElse: () => widget.category,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(freshCat.title),
          ),
          body: Column(
            children: [
              // Category Header Summary Box
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [freshCat.color.withOpacity(0.9), freshCat.color.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: freshCat.color.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          freshCat.icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${freshCat.entries} logs recorded",
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "TOTAL CATEGORY OUTFLOW",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                              Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "$currency ",
                                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  freshCat.totalAmount.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Category Monthly Budget Progress Bar & Info
                            if (freshCat.budgetLimit > 0) ...[
                              Builder(builder: (context) {
                                final percent = (freshCat.totalAmount / freshCat.budgetLimit).clamp(0.0, 1.0);
                                final isOver = freshCat.totalAmount > freshCat.budgetLimit;
                                final Color barColor = freshCat.totalAmount > freshCat.budgetLimit
                                    ? Colors.redAccent
                                    : percent > 0.75
                                        ? Colors.orangeAccent
                                        : Colors.greenAccent;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        backgroundColor: Colors.white24,
                                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isOver
                                          ? "⚠️ Over budget limit by $currency ${(freshCat.totalAmount - freshCat.budgetLimit).toStringAsFixed(0)}"
                                          : "${(percent * 100).toStringAsFixed(0)}% of $currency ${freshCat.budgetLimit.toStringAsFixed(0)} limit",
                                      style: TextStyle(
                                        color: isOver ? Colors.yellowAccent : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.white),
                        tooltip: "Set Budget Limit",
                        onPressed: () => _showSetBudgetDialog(context, provider, freshCat),
                      ),
                    ],
                  ),
                ),
              ),

              // Title Feed
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "OUTFLOW LIST",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5),
                    ),
                    Icon(Icons.timeline_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),

              // Outflow Feed List
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final dateStr = DateFormat('dd MMMM yyyy').format(item.date);

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
                                        _showEditExpenseDialog(context, item);
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
                                        provider.deleteExpense(item.id!, item.category, item.amount);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Expense entry deleted"), backgroundColor: Colors.orange),
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
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: Text(
                                    "- $currency${item.amount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: freshCat.color,
            foregroundColor: Colors.white,
            onPressed: () => _showAddExpenseDialog(context),
            child: const Icon(Icons.add_shopping_cart_rounded),
          ),
        );
      },
    );
  }

  void _showSetBudgetDialog(BuildContext context, KhataProvider provider, ExpenseCategory cat) {
    final controller = TextEditingController(text: cat.budgetLimit > 0 ? cat.budgetLimit.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Set Budget for ${cat.title}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Set a monthly spending limit for this category. You will get alerts when spending nears or exceeds this limit.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Monthly Budget Limit (${provider.currencySymbol})",
                  hintText: "e.g. 15000",
                ),
              ),
            ],
          ),
          actions: [
            if (cat.budgetLimit > 0)
              TextButton(
                onPressed: () async {
                  await provider.updateCategoryBudget(cat.title, 0.0);
                  if (mounted) Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Remove Budget"),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final limit = double.tryParse(controller.text.trim()) ?? 0.0;
                await provider.updateCategoryBudget(cat.title, limit);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("Save Budget"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            "No expenses in this category",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
