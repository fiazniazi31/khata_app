import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../providers/khata_provider.dart';
import '../widgets/balance_card.dart';
import 'add_customer_screen.dart';
import 'customer_ledger_screen.dart';
import 'settings_screen.dart';
import 'expense_tab.dart'; // v3
import 'analytics_tab.dart'; // v5
import 'accounts_screen.dart'; // v5
import 'savings_screen.dart'; // v6

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0; // v3

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, KhataProvider provider, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Customer?"),
        content: Text(
          "Are you sure you want to delete ${customer.name}?\n\nThis will also permanently delete all transaction history for this customer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteCustomer(customer.id!, customer.name);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Customer ledger deleted"),
                  backgroundColor: Colors.orange,
                ),
              );
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

    return Consumer<KhataProvider>(
      builder: (context, provider, child) {
        final currency = provider.currencySymbol;
        final list = provider.customers;

        // Tab Bodies Selection
        final List<Widget> tabBodies = [
          // Tab 0: Khata Book Tab
          Column(
            children: [
              // Summary card section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: BalanceCard(provider: provider),
              ),

              // Savings Summary Card (v6)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentTabIndex = 2; // Switch to Savings tab
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.savings_outlined, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Savings",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$currency ${provider.totalSavingsBalance.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "This Month",
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${provider.currentMonthNetSavings >= 0 ? '+' : '-'} $currency${provider.currentMonthNetSavings.abs().toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: provider.currentMonthNetSavings >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),

              // Search & Filter Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search customer or phone...",
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    provider.setSearchQuery(val);
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Horizontal Tabs Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterTab(
                      context: context,
                      label: "All Customers",
                      isSelected: provider.activeFilter == CustomerFilter.all,
                      onTap: () => provider.setFilter(CustomerFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      context: context,
                      label: "You Get",
                      isSelected: provider.activeFilter == CustomerFilter.oweYou,
                      onTap: () => provider.setFilter(CustomerFilter.oweYou),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterTab(
                      context: context,
                      label: "You Give",
                      isSelected: provider.activeFilter == CustomerFilter.youOwe,
                      onTap: () => provider.setFilter(CustomerFilter.youOwe),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // List of customers
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final customer = list[index];
                              final net = provider.getCustomerNetBalance(customer.name);
                              final netAbs = net.abs();
                              final isOweYou = net > 0;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Slidable(
                                    key: ValueKey(customer.id),
                                    startActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      extentRatio: 0.25,
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) {
                                            Clipboard.setData(ClipboardData(text: customer.phone));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Phone: ${customer.phone} copied to clipboard!"),
                                                backgroundColor: theme.primaryColor,
                                              ),
                                            );
                                          },
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          icon: Icons.phone_outlined,
                                          label: 'Copy Phone',
                                        ),
                                      ],
                                    ),
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      extentRatio: 0.25,
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) => _confirmDelete(context, provider, customer),
                                          backgroundColor: const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete_outline_rounded,
                                          label: 'Delete',
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      title: Text(
                                        customer.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            customer.phone,
                                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            customer.paymentPurpose,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            net == 0
                                                ? "Settle"
                                                : "${isOweYou ? '+' : '-'} $currency${netAbs.toStringAsFixed(0)}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: net == 0
                                                  ? Colors.grey
                                                  : isOweYou
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFEF4444),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            net == 0
                                                ? "Cleared"
                                                : isOweYou
                                                    ? "YOU GET"
                                                    : "YOU GIVE",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: (net == 0
                                                      ? Colors.grey
                                                      : isOweYou
                                                          ? const Color(0xFF10B981)
                                                          : const Color(0xFFEF4444))
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CustomerLedgerScreen(customer: customer),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          
          // Tab 1: Expense Tracker Tab
          const ExpenseTab(),

          // Tab 2: Savings Tab (v6)
          const SavingsScreen(),

          // Tab 3: Analytics Tab (v5)
          const AnalyticsTab(),
        ];

        final titles = ["Khata Book", "Expense Tracker", "Savings", "Analytics & Insights"];

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_currentTabIndex]),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: "Accounts & Wallets",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          body: tabBodies[_currentTabIndex],
          
          // Dynamic Floating Action Button
          floatingActionButton: _currentTabIndex == 0
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded),
                )
              : null,
              
          // Bottom Navigation Bar
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: "Khata Ledger",
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments_rounded),
                label: "Expenses",
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings_rounded),
                label: "Savings",
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: "Analytics",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterTab({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded, size: 48, color: theme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              "No customers found",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? "Try refining your search text."
                  : "Tap the + button below to add your first customer and start logging accounts.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
