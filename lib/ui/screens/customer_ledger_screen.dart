import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import '../../providers/khata_provider.dart';
import '../../utils/pdf_helper.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/transaction_tile.dart';
import 'add_customer_screen.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final Customer customer;

  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KhataProvider>(context, listen: false)
          .loadTransactionsForCustomer(widget.customer.name);
    });
  }

  void _showAddTransactionSheet(BuildContext context, String type) {
    final isGive = type == 'give';
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final currencySymbol = Provider.of<KhataProvider>(context, listen: false).currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isGive 
                          ? "You Give (Pay) to ${widget.customer.name}"
                          : "You Take (Receive) from ${widget.customer.name}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isGive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Text Field
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "0.00",
                    prefixIcon: Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Text(
                        currencySymbol,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isGive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    labelText: "Transaction Amount",
                    labelStyle: TextStyle(
                      color: isGive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
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

                // Note/Remarks Text Field
                TextFormField(
                  controller: descController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: "Enter remarks (e.g. Received cash, Milk payment)",
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    labelText: "Transaction Note (Optional)",
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final price = double.parse(priceController.text);
                    final desc = descController.text.trim();

                    final newTx = TransactionModel(
                      customerName: widget.customer.name,
                      price: price,
                      type: type,
                      description: desc,
                      date: DateTime.now(),
                    );

                    final provider = Provider.of<KhataProvider>(context, listen: false);
                    final success = await provider.addTransaction(newTx);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Transaction recorded successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Failed to save transaction"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save Transaction"),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePdfExport(KhataProvider provider) async {
    final give = provider.getCustomerGiveBalance(widget.customer.name);
    final take = provider.getCustomerTakeBalance(widget.customer.name);
    final net = provider.getCustomerNetBalance(widget.customer.name);

    final file = await PdfHelper.generateLedgerPdf(
      customer: widget.customer,
      transactions: provider.activeTransactions,
      totalGive: give,
      totalTake: take,
      netBalance: net,
      currency: provider.currencySymbol,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${widget.customer.name} Ledger Account Statement',
      text: 'Sharing account statement for ${widget.customer.name}. Generated via Khata Book.',
    );
  }

  void _confirmDeleteCustomer(BuildContext context, KhataProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Customer?"),
        content: Text(
          "Are you sure you want to delete ${widget.customer.name}?\n\nThis will also permanently delete all transaction history for this customer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteCustomer(widget.customer.id!, widget.customer.name);
              if (context.mounted) {
                Navigator.pop(context); // Pop ledger details back to dashboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Customer ledger deleted"),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<KhataProvider>(
      builder: (context, provider, child) {
        final currency = provider.currencySymbol;
        final list = provider.activeTransactions;
        final net = provider.getCustomerNetBalance(widget.customer.name);
        final netAbs = net.abs();
        final isOweYou = net > 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: "Export PDF",
                onPressed: () => _handlePdfExport(provider),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCustomerScreen(customer: widget.customer),
                      ),
                    );
                  } else if (val == 'copy') {
                    Clipboard.setData(ClipboardData(text: widget.customer.phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Phone copied: ${widget.customer.phone}"), backgroundColor: theme.primaryColor),
                    );
                  } else if (val == 'delete') {
                    _confirmDeleteCustomer(context, provider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit Details")),
                  const PopupMenuItem(value: 'copy', child: Text("Copy Phone No")),
                  const PopupMenuItem(value: 'delete', child: Text("Delete Customer", style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Customer Summary Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Circular Initials Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : '?',
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.phone,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Purpose: ${widget.customer.paymentPurpose}",
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Net state bubble
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: net == 0
                              ? Colors.grey.withOpacity(0.1)
                              : (isOweYou ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          net == 0
                              ? "Settled"
                              : "${isOweYou ? 'Get' : 'Give'} $currency${netAbs.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: net == 0
                                ? Colors.grey
                                : isOweYou
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Running Ledger Canvas Trend Chart
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: AnalyticsChart(transactions: list, currency: currency),
                ),

              // Ledger Transactions Headings
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("TRANSACTIONS HISTORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
                    Icon(Icons.arrow_downward, size: 14, color: Colors.grey),
                  ],
                ),
              ),

              // Ledger Items Feed List
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyTransactions(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return TransactionTile(
                            transaction: item,
                            currency: currency,
                            onDelete: () {
                              provider.deleteTransaction(item.id!, widget.customer.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Transaction entry deleted"), backgroundColor: Colors.orange),
                              );
                            },
                          );
                        },
                      ),
              ),

              // Bottom Split action sheet trigger buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Give (Pay) button
                    Expanded(
                      child: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ).wrap(
                        ElevatedButton(
                          onPressed: () => _showAddTransactionSheet(context, 'give'),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text("YOU GIVE (PAY)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Take (Receive) button
                    Expanded(
                      child: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ).wrap(
                        ElevatedButton(
                          onPressed: () => _showAddTransactionSheet(context, 'take'),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text("YOU TAKE (GET)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTransactions(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horizontal_circle_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              "No transaction logs found",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tap GIVE or TAKE below to log your first transaction record.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Helper extensions to wrap standard style modifiers
extension on ButtonStyle {
  Widget wrap(ElevatedButton button) {
    return ElevatedButton(
      onPressed: button.onPressed,
      style: this,
      child: button.child,
    );
  }
}
