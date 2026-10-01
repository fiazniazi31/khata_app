import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/savings_transaction.dart';
import '../../providers/khata_provider.dart';
import '../../utils/pdf_helper.dart';

enum SavingsTypeFilter { all, deposits, withdrawals }
enum SavingsPeriodFilter { month, allTime, year, customRange }

class SavingsScreen extends StatefulWidget {
  final bool showAppBar;
  const SavingsScreen({super.key, this.showAppBar = false});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  SavingsTypeFilter _typeFilter = SavingsTypeFilter.all;
  SavingsPeriodFilter _periodFilter = SavingsPeriodFilter.month;
  DateTimeRange? _customDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickMonth(BuildContext context, KhataProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedSavingsMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      provider.setSelectedSavingsMonth(DateTime(picked.year, picked.month));
    }
  }

  void _showAddOrEditSheet(BuildContext context, {SavingsTransaction? editTransaction, SavingsTransactionType initialType = SavingsTransactionType.deposit}) {
    final provider = Provider.of<KhataProvider>(context, listen: false);
    final currency = provider.currencySymbol;
    final isEditing = editTransaction != null;

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: isEditing ? editTransaction.amount.toStringAsFixed(2) : '',
    );
    final noteController = TextEditingController(
      text: isEditing ? editTransaction.note : '',
    );

    DateTime selectedDate = isEditing ? editTransaction.transactionDate : DateTime.now();
    SavingsTransactionType selectedType = isEditing ? editTransaction.transactionType : initialType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setModalState(() {
                  selectedDate = picked;
                });
              }
            }

            final totalBalance = provider.totalSavingsBalance;
            final isWithdrawal = selectedType == SavingsTransactionType.withdrawal;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing
                                ? "Edit Savings Transaction"
                                : (isWithdrawal ? "Withdraw from Savings" : "Add Savings Deposit"),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isWithdrawal ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Type Selector Toggle (Deposit / Withdrawal)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    selectedType = SavingsTransactionType.deposit;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedType == SavingsTransactionType.deposit
                                        ? const Color(0xFF10B981)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward_rounded,
                                        size: 16,
                                        color: selectedType == SavingsTransactionType.deposit
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Deposit",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: selectedType == SavingsTransactionType.deposit
                                              ? Colors.white
                                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    selectedType = SavingsTransactionType.withdrawal;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedType == SavingsTransactionType.withdrawal
                                        ? const Color(0xFFEF4444)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 16,
                                        color: selectedType == SavingsTransactionType.withdrawal
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Withdrawal",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: selectedType == SavingsTransactionType.withdrawal
                                              ? Colors.white
                                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // If Withdrawal, show available balance
                      if (isWithdrawal)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Available savings balance: $currency${totalBalance.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isWithdrawal) const SizedBox(height: 12),

                      // Amount Input
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "0.00",
                          prefixIcon: Container(
                            width: 48,
                            alignment: Alignment.center,
                            child: Text(
                              currency,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          labelText: isWithdrawal ? "Withdrawal Amount" : "Deposit Amount",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Amount is required";
                          }
                          final numVal = double.tryParse(value);
                          if (numVal == null || numVal <= 0) {
                            return "Enter a valid amount greater than 0";
                          }
                          if (selectedType == SavingsTransactionType.withdrawal && !isEditing) {
                            if (numVal > totalBalance) {
                              return "Insufficient savings balance.\nAvailable: $currency${totalBalance.toStringAsFixed(2)}";
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Picker Box
                      InkWell(
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
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              const Text(
                                "Change Date",
                                style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Note Input (Optional)
                      TextFormField(
                        controller: noteController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "e.g., Monthly saving, Emergency fund, Bonus",
                          prefixIcon: Icon(Icons.note_alt_outlined),
                          labelText: "Note / Description (Optional)",
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isWithdrawal ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final amt = double.parse(amountController.text.trim());
                          final note = noteController.text.trim();

                          if (isEditing) {
                            final updated = editTransaction.copyWith(
                              amount: amt,
                              transactionType: selectedType,
                              transactionDate: selectedDate,
                              note: note,
                              updatedAt: DateTime.now(),
                            );
                            final error = await provider.updateSavingsTransaction(updated);
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Savings transaction updated successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            final newTx = SavingsTransaction(
                              amount: amt,
                              transactionType: selectedType,
                              transactionDate: selectedDate,
                              note: note,
                            );
                            final error = await provider.addSavingsTransaction(newTx);
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isWithdrawal
                                      ? "Withdrawn $currency${amt.toStringAsFixed(2)} from savings"
                                      : "Deposited $currency${amt.toStringAsFixed(2)} to savings",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          isEditing
                              ? "Save Changes"
                              : (isWithdrawal ? "Confirm Withdrawal" : "Save Deposit"),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, KhataProvider provider, SavingsTransaction tx) {
    final currency = provider.currencySymbol;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: Text(
          "Are you sure you want to delete this ${tx.isDeposit ? 'Deposit' : 'Withdrawal'} of $currency${tx.amount.toStringAsFixed(2)}?\n\nThis will update your savings balance accordingly.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await provider.deleteSavingsTransaction(tx.id!);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Savings transaction deleted"),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPdfExportDialog(BuildContext context, KhataProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Export Savings Report (PDF)",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Select statement period for the PDF report:",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFF10B981)),
                title: Text("Current Month (${DateFormat('MMMM yyyy').format(DateTime.now())})"),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndSharePdf(
                    context,
                    provider,
                    periodType: 'current_month',
                    customMonth: DateTime.now(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.teal),
                title: Text("Selected Month (${DateFormat('MMMM yyyy').format(provider.selectedSavingsMonth)})"),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndSharePdf(
                    context,
                    provider,
                    periodType: 'selected_month',
                    customMonth: provider.selectedSavingsMonth,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.indigo),
                title: Text("Selected Year (${provider.selectedSavingsMonth.year})"),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndSharePdf(
                    context,
                    provider,
                    periodType: 'selected_year',
                    year: provider.selectedSavingsMonth.year,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive, color: Colors.blue),
                title: const Text("All Transactions (All Time)"),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndSharePdf(context, provider, periodType: 'all_time');
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune, color: Colors.orange),
                title: const Text("Custom Date Range..."),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _generateAndSharePdf(
                      context,
                      provider,
                      periodType: 'custom_range',
                      range: picked,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateAndSharePdf(
    BuildContext context,
    KhataProvider provider, {
    required String periodType,
    DateTime? customMonth,
    int? year,
    DateTimeRange? range,
  }) async {
    try {
      final allWithBalance = provider.allSavingsWithRunningBalance;

      String periodTitle = "All Time";
      DateTime? startDate;
      DateTime? endDate;

      if (periodType == 'current_month' || periodType == 'selected_month') {
        final m = customMonth ?? DateTime.now();
        periodTitle = DateFormat('MMMM yyyy').format(m);
        startDate = DateTime(m.year, m.month, 1);
        endDate = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      } else if (periodType == 'selected_year') {
        final y = year ?? DateTime.now().year;
        periodTitle = "Year $y";
        startDate = DateTime(y, 1, 1);
        endDate = DateTime(y, 12, 31, 23, 59, 59);
      } else if (periodType == 'custom_range' && range != null) {
        periodTitle = "${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}";
        startDate = range.start;
        endDate = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      }

      double openingBalance = 0.0;
      List<SavingsTransaction> periodTransactions = [];

      if (startDate != null && endDate != null) {
        // Transactions prior to start date
        final prior = allWithBalance.where((t) => t.transactionDate.isBefore(startDate!));
        final priorDep = prior.where((t) => t.isDeposit).fold(0.0, (sum, t) => sum + t.amount);
        final priorWdr = prior.where((t) => t.isWithdrawal).fold(0.0, (sum, t) => sum + t.amount);
        openingBalance = priorDep - priorWdr;

        periodTransactions = allWithBalance.where((t) =>
            !t.transactionDate.isBefore(startDate!) && !t.transactionDate.isAfter(endDate!)).toList();
      } else {
        openingBalance = 0.0;
        periodTransactions = allWithBalance;
      }

      final totalDeposits = periodTransactions.where((t) => t.isDeposit).fold(0.0, (sum, t) => sum + t.amount);
      final totalWithdrawals = periodTransactions.where((t) => t.isWithdrawal).fold(0.0, (sum, t) => sum + t.amount);
      final closingBalance = openingBalance + totalDeposits - totalWithdrawals;

      final file = await PdfHelper.generateSavingsReportPdf(
        periodTitle: periodTitle,
        openingBalance: openingBalance,
        totalDeposits: totalDeposits,
        totalWithdrawals: totalWithdrawals,
        closingBalance: closingBalance,
        transactions: periodTransactions,
        currency: provider.currencySymbol,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Khata App - Savings Statement - $periodTitle',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<KhataProvider>(
      builder: (context, provider, child) {
        final selectedMonth = provider.selectedSavingsMonth;
        final monthStr = DateFormat('MMMM yyyy').format(selectedMonth);

        // Compute running balances for all transactions across time
        final allWithBalances = provider.allSavingsWithRunningBalance;

        // Apply Time Filter
        List<SavingsTransaction> periodFiltered;
        if (_periodFilter == SavingsPeriodFilter.month) {
          periodFiltered = allWithBalances.where((t) =>
            t.transactionDate.year == selectedMonth.year &&
            t.transactionDate.month == selectedMonth.month
          ).toList();
        } else if (_periodFilter == SavingsPeriodFilter.year) {
          periodFiltered = allWithBalances.where((t) =>
            t.transactionDate.year == selectedMonth.year
          ).toList();
        } else if (_periodFilter == SavingsPeriodFilter.customRange && _customDateRange != null) {
          final start = _customDateRange!.start;
          final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
          periodFiltered = allWithBalances.where((t) =>
            !t.transactionDate.isBefore(start) && !t.transactionDate.isAfter(end)
          ).toList();
        } else {
          periodFiltered = allWithBalances;
        }

        // Apply Type Filter
        if (_typeFilter == SavingsTypeFilter.deposits) {
          periodFiltered = periodFiltered.where((t) => t.isDeposit).toList();
        } else if (_typeFilter == SavingsTypeFilter.withdrawals) {
          periodFiltered = periodFiltered.where((t) => t.isWithdrawal).toList();
        }

        // Apply Search Filter by Note
        final query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          periodFiltered = periodFiltered.where((t) =>
            t.note.toLowerCase().contains(query)
          ).toList();
        }

        // Present newest first
        final displayList = List<SavingsTransaction>.from(periodFiltered)
          ..sort((a, b) {
            final cmp = b.transactionDate.compareTo(a.transactionDate);
            if (cmp != 0) return cmp;
            return (b.id ?? 0).compareTo(a.id ?? 0);
          });

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: const Text("Savings"),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: "Export PDF",
                      onPressed: () => _showPdfExportDialog(context, provider),
                    ),
                  ],
                )
              : null,
          body: Column(
            children: [
              // 1. Month Picker Controller Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      onPressed: () {
                        provider.setSelectedSavingsMonth(
                          DateTime(selectedMonth.year, selectedMonth.month - 1),
                        );
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
                        provider.setSelectedSavingsMonth(
                          DateTime(selectedMonth.year, selectedMonth.month + 1),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 2. Savings Balance & Monthly Summary Hero Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _buildSavingsHeroCard(context, provider, isDark),
              ),

              const SizedBox(height: 10),

              // 3. Action Buttons (+ Add Saving, Withdraw, PDF)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAddOrEditSheet(
                          context,
                          initialType: SavingsTransactionType.deposit,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          "Add Saving",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                        ),
                        onPressed: () => _showAddOrEditSheet(
                          context,
                          initialType: SavingsTransactionType.withdrawal,
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFFEF4444)),
                        label: const Text(
                          "Withdraw",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: "Export PDF Report",
                      onPressed: () => _showPdfExportDialog(context, provider),
                      icon: Icon(Icons.picture_as_pdf_outlined, color: theme.primaryColor, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 4. Search and Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search notes...",
                            prefixIcon: const Icon(Icons.search, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Period Filter Menu
                    PopupMenuButton<SavingsPeriodFilter>(
                      initialValue: _periodFilter,
                      tooltip: "Filter Time Period",
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(Icons.filter_alt_outlined, size: 20, color: theme.primaryColor),
                      ),
                      onSelected: (val) async {
                        if (val == SavingsPeriodFilter.customRange) {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _periodFilter = val;
                              _customDateRange = picked;
                            });
                          }
                        } else {
                          setState(() {
                            _periodFilter = val;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SavingsPeriodFilter.month,
                          child: Text("Selected Month"),
                        ),
                        const PopupMenuItem(
                          value: SavingsPeriodFilter.year,
                          child: Text("Selected Year"),
                        ),
                        const PopupMenuItem(
                          value: SavingsPeriodFilter.allTime,
                          child: Text("All Time"),
                        ),
                        const PopupMenuItem(
                          value: SavingsPeriodFilter.customRange,
                          child: Text("Custom Date Range..."),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 5. Horizontal Type Filters (All / Deposits / Withdrawals)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTypeFilterChip(
                      label: "All (${periodFiltered.length})",
                      isSelected: _typeFilter == SavingsTypeFilter.all,
                      onTap: () => setState(() => _typeFilter = SavingsTypeFilter.all),
                      isDark: isDark,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip(
                      label: "Deposits",
                      isSelected: _typeFilter == SavingsTypeFilter.deposits,
                      onTap: () => setState(() => _typeFilter = SavingsTypeFilter.deposits),
                      isDark: isDark,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip(
                      label: "Withdrawals",
                      isSelected: _typeFilter == SavingsTypeFilter.withdrawals,
                      onTap: () => setState(() => _typeFilter = SavingsTypeFilter.withdrawals),
                      isDark: isDark,
                      theme: theme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 6. Transactions List
              Expanded(
                child: displayList.isEmpty
                    ? _buildEmptyState(theme, context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final tx = displayList[index];
                          return _buildTransactionTile(context, provider, tx, isDark, theme);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavingsHeroCard(BuildContext context, KhataProvider provider, bool isDark) {
    final currency = provider.currencySymbol;
    final totalBalance = provider.totalSavingsBalance;
    final monthDeposited = provider.monthlySavingsDeposited;
    final monthWithdrawn = provider.monthlySavingsWithdrawn;
    final monthNet = provider.monthlyNetSavings;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SAVINGS BALANCE (ALL TIME)",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 13),
                          SizedBox(width: 4),
                          Text(
                            "Secured",
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "$currency ",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      totalBalance.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Colors.white12),
                const SizedBox(height: 10),

                // This Month Summary breakdown
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 12),
                              SizedBox(width: 3),
                              Text("Deposited", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$currency${monthDeposited.toStringAsFixed(0)}",
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 26, color: Colors.white12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 12),
                              SizedBox(width: 3),
                              Text("Withdrawn", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$currency${monthWithdrawn.toStringAsFixed(0)}",
                            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 26, color: Colors.white12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.tealAccent, size: 12),
                              SizedBox(width: 3),
                              Text("Net Month", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${monthNet >= 0 ? '+' : '-'} $currency${monthNet.abs().toStringAsFixed(0)}",
                            style: TextStyle(
                              color: monthNet >= 0 ? Colors.tealAccent : const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    KhataProvider provider,
    SavingsTransaction tx,
    bool isDark,
    ThemeData theme,
  ) {
    final currency = provider.currencySymbol;
    final isDep = tx.isDeposit;
    final formattedDate = DateFormat('dd MMM yyyy').format(tx.transactionDate);
    final runningBal = tx.runningBalance != null ? tx.runningBalance!.toStringAsFixed(2) : '0.00';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Slidable(
          key: ValueKey(tx.id),
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (context) => _showAddOrEditSheet(context, editTransaction: tx),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit_rounded,
                label: 'Edit',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (context) => _confirmDelete(context, provider, tx),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDep ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDep ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isDep ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 20,
              ),
            ),
            title: Text(
              tx.note.isNotEmpty ? tx.note : (isDep ? "Savings Deposit" : "Savings Withdrawal"),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDep ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDep ? "DEPOSIT" : "WITHDRAWAL",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDep ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Balance: $currency$runningBal",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
            trailing: Text(
              "${isDep ? '+' : '-'} $currency${tx.amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDep ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
            onTap: () => _showAddOrEditSheet(context, editTransaction: tx),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.savings_outlined, size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 12),
            Text(
              "No savings transactions yet",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? "No transactions match your search filter."
                  : "Start building your savings by adding your first saving deposit.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => _showAddOrEditSheet(context, initialType: SavingsTransactionType.deposit),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Add First Saving", style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
