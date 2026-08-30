import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/account.dart';
import '../../models/account_transfer.dart';
import '../../providers/khata_provider.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KhataProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = provider.currencySymbol;
    final accounts = provider.accounts;
    final transfers = provider.accountTransfers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transfer Money',
            onPressed: () => _showTransferDialog(context, provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context, provider),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Add Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
        ),
        shape: const StadiumBorder(),
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Header
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Accounts Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$symbol ${provider.totalAccountBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showTransferDialog(context, provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF11998E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.compare_arrows, size: 18),
                        label: const Text('Transfer Funds', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Accounts List Section
            Text(
              'Your Financial Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            accounts.isEmpty
                ? const Center(child: Text("No accounts added yet."))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: acc.color.withOpacity(0.15),
                            child: Icon(acc.icon, color: acc.color),
                          ),
                          title: Text(
                            acc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${acc.type.toUpperCase()}${acc.accountNumber.isNotEmpty ? ' • ${acc.accountNumber}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '$symbol ${acc.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: acc.balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          onTap: () => _showEditAccountDialog(context, provider, acc),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),

            // Recent Transfers Section
            if (transfers.isNotEmpty) ...[
              Text(
                'Recent Transfers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transfers.length > 5 ? 5 : transfers.length,
                itemBuilder: (context, index) {
                  final tr = transfers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                      title: Text('${tr.fromAccountName} → ${tr.toAccountName}'),
                      subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(tr.date)),
                      trailing: Text(
                        '$symbol ${tr.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, KhataProvider provider) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    String selectedType = 'bank';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Name (e.g. HBL Bank, JazzCash)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Account Type'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                    DropdownMenuItem(value: 'wallet', child: Text('Mobile Wallet')),
                    DropdownMenuItem(value: 'card', child: Text('Credit/Debit Card')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedType = val;
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Balance'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Account / Card Number (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final balance = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
                if (name.isNotEmpty) {
                  await provider.addAccount(Account(
                    name: name,
                    type: selectedType,
                    balance: balance,
                    accountNumber: numberCtrl.text.trim(),
                  ));
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAccountDialog(BuildContext context, KhataProvider provider, Account acc) {
    final nameCtrl = TextEditingController(text: acc.name);
    final balanceCtrl = TextEditingController(text: acc.balance.toString());
    final numberCtrl = TextEditingController(text: acc.accountNumber);
    String selectedType = acc.type;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Name'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Account Type'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                    DropdownMenuItem(value: 'wallet', child: Text('Mobile Wallet')),
                    DropdownMenuItem(value: 'card', child: Text('Credit/Debit Card')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedType = val;
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Current Balance'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Account Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (acc.id != null) {
                  await provider.deleteAccount(acc.id!);
                  if (mounted) Navigator.pop(ctx);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final balance = double.tryParse(balanceCtrl.text.trim()) ?? acc.balance;
                if (name.isNotEmpty) {
                  await provider.updateAccount(acc.copyWith(
                    name: name,
                    type: selectedType,
                    balance: balance,
                    accountNumber: numberCtrl.text.trim(),
                  ));
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showTransferDialog(BuildContext context, KhataProvider provider) {
    final accounts = provider.accounts;
    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 accounts are required to transfer money.')),
      );
      return;
    }

    int fromAccId = accounts.first.id!;
    int toAccId = accounts[1].id!;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final fromAcc = accounts.firstWhere((a) => a.id == fromAccId, orElse: () => accounts.first);
            final toAcc = accounts.firstWhere((a) => a.id == toAccId, orElse: () => accounts.last);

            return AlertDialog(
              title: const Text('Inter-Account Transfer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: fromAccId,
                      decoration: const InputDecoration(labelText: 'From Account (Sender)'),
                      items: accounts.map((acc) {
                        return DropdownMenuItem<int>(
                          value: acc.id,
                          child: Text('${acc.name} (${provider.currencySymbol}${acc.balance.toStringAsFixed(0)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateSB(() => fromAccId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Icon(Icons.arrow_downward, color: Colors.grey),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: toAccId,
                      decoration: const InputDecoration(labelText: 'To Account (Receiver)'),
                      items: accounts.map((acc) {
                        return DropdownMenuItem<int>(
                          value: acc.id,
                          child: Text('${acc.name} (${provider.currencySymbol}${acc.balance.toStringAsFixed(0)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateSB(() => toAccId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Transfer Amount',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Note (Optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }
                    if (fromAccId == toAccId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sender and receiver accounts must be different')),
                      );
                      return;
                    }

                    final transfer = AccountTransfer(
                      fromAccountId: fromAccId,
                      toAccountId: toAccId,
                      fromAccountName: fromAcc.name,
                      toAccountName: toAcc.name,
                      amount: amount,
                      date: DateTime.now(),
                      note: noteCtrl.text.trim(),
                    );

                    final success = await provider.transferMoney(transfer);
                    if (mounted) {
                      Navigator.pop(ctx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Transferred ${provider.currencySymbol}$amount successfully!')),
                        );
                      }
                    }
                  },
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
