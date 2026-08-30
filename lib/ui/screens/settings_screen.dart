import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../providers/khata_provider.dart';
import '../../utils/backup_helper.dart';
import '../../utils/biometric_helper.dart';
import 'pin_lock_screen.dart';
import 'accounts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<File> _availableBackups = [];

  @override
  void initState() {
    super.initState();
    _scanForBackups();
  }

  Future<void> _scanForBackups() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      final files = await dir.list().toList();
      
      final backups = files
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('khata_backup_') && p.basename(f.path).endsWith('.json'))
          .toList();
          
      setState(() {
        _availableBackups = backups;
      });
    } catch (e) {
      print("Scan backups error: $e");
    }
  }

  void _changeCurrency(BuildContext context, KhataProvider provider) {
    final currencies = ['Rs.', '\$', '\u20B9', '\u20AC', '\u00A3', '\u00A5', 'AED'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Currency Symbol",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final curr = currencies[index];
                    final isSelected = provider.currencySymbol == curr;
                    return ListTile(
                      title: Text(curr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      onTap: () {
                        provider.setCurrencySymbol(curr);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleBackupExport(KhataProvider provider) async {
    final file = await BackupHelper.exportBackup();
    if (file != null && await file.exists()) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Khata Book Ledger Backup',
        text: 'Backup file exported from Khata App on ${DateTime.now().toLocal()}',
      );
      _scanForBackups(); // Refresh scanned backups list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to export backup"), backgroundColor: Colors.red),
      );
    }
  }

  void _handleRawJsonImport(KhataProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paste Backup JSON"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Paste the raw JSON content of your exported backup to restore accounts and ledger entries.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(
                hintText: '{"backupVersion":2,...}',
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final jsonText = controller.text.trim();
              if (jsonText.isEmpty) return;

              try {
                // Save JSON temporary to call backup helper
                final tempDir = await getTemporaryDirectory();
                final file = File(p.join(tempDir.path, 'imported_backup.json'));
                await file.writeAsString(jsonText);

                final success = await BackupHelper.importBackup(file);
                if (success) {
                  await provider.refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Database restored successfully!"), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                } else {
                  throw Exception("Restore helper failed");
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid backup JSON format!"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Restore"),
          ),
        ],
      ),
    );
  }

  void _restoreScannedBackup(File file, KhataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restore Backup?"),
        content: Text(
          "Are you sure you want to restore from ${p.basename(file.path)}?\n\nThis will overwrite all existing customer records and transaction ledgers.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final success = await BackupHelper.importBackup(file);
              if (success) {
                await provider.refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Database restored successfully!"), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to restore from backup file"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Restore"),
          ),
        ],
      ),
    );
  }

  void _handleResetApp(KhataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data?", style: TextStyle(color: Colors.red)),
        content: const Text(
          "This will permanently delete all customers and their transactions from this device. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await provider.wipeAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All data deleted successfully"), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            },
            child: const Text("Wipe Data", style: TextStyle(color: Colors.red)),
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
        return Scaffold(
          appBar: AppBar(
            title: const Text("App Settings"),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Theme settings
              _buildSectionHeader("Appearance & Locale"),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.primaryColor),
                      title: const Text("Dark Theme Mode"),
                      subtitle: const Text("Switch between light and dark backgrounds"),
                      trailing: Switch(
                        value: isDark,
                        activeColor: theme.primaryColor,
                        onChanged: (val) {
                          provider.toggleTheme(val);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.currency_exchange_rounded, color: theme.primaryColor),
                      title: const Text("Ledger Currency"),
                      subtitle: const Text("Select currency symbol for totals"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.currencySymbol,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        ],
                      ),
                      onTap: () => _changeCurrency(context, provider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
                      title: const Text("Accounts & Wallets"),
                      subtitle: const Text("Manage Cash, Bank Accounts & Mobile Wallets"),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Security PIN & Biometrics Settings
              _buildSectionHeader("Security & Privacy"),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        provider.pinLockEnabled ? Icons.lock : Icons.lock_open,
                        color: provider.pinLockEnabled ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      title: const Text("App PIN Lock Security"),
                      subtitle: Text(
                        provider.pinLockEnabled 
                            ? "Protected by 4-digit PIN lock" 
                            : "Enable PIN code request on app launch",
                      ),
                      trailing: Switch(
                        value: provider.pinLockEnabled,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) async {
                          if (val) {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (context) => const PinLockScreen(isVerifying: false)),
                            );
                            if (result != true) {
                              provider.disablePinLock();
                            }
                          } else {
                            provider.disablePinLock();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Security lock disabled"), backgroundColor: Colors.orange),
                            );
                          }
                        },
                      ),
                    ),
                    if (provider.pinLockEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.fingerprint, color: Colors.blue),
                        title: const Text("Biometric Lock (Fingerprint/FaceID)"),
                        subtitle: const Text("Unlock app using device biometrics"),
                        trailing: Switch(
                          value: provider.biometricLockEnabled,
                          activeColor: Colors.blue,
                          onChanged: (val) async {
                            if (val) {
                              final available = await BiometricHelper.isBiometricAvailable();
                              if (!available) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("No biometrics (Fingerprint/Face) found or enrolled on this device."),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                                return;
                              }
                              final success = await BiometricHelper.authenticate(
                                localizedReason: 'Verify your fingerprint/face to enable Biometric Lock',
                              );
                              if (success) {
                                provider.toggleBiometrics(true);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Biometric Lock enabled successfully!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            } else {
                              provider.toggleBiometrics(false);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Backup & Restore
              _buildSectionHeader("Database Backup & Restore"),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                      title: const Text("Export & Share Backup File"),
                      subtitle: const Text("Export complete ledger & expense data as a JSON file"),
                      trailing: const Icon(Icons.share_outlined),
                      onTap: () => _handleBackupExport(provider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.paste_rounded, color: Colors.teal),
                      title: const Text("Import Backup from JSON Text"),
                      subtitle: const Text("Paste backup JSON text directly to restore"),
                      trailing: const Icon(Icons.restore_page_rounded),
                      onTap: () => _handleRawJsonImport(provider),
                    ),
                    if (_availableBackups.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.restore_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text("Local Export History", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _availableBackups.length,
                        itemBuilder: (context, index) {
                          final file = _availableBackups[index];
                          final name = p.basename(file.path);
                          return ListTile(
                            dense: true,
                            title: Text(name, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                            trailing: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                            onTap: () => _restoreScannedBackup(file, provider),
                          );
                        },
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Danger Zone
              _buildSectionHeader("System Operations"),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text("Reset Application", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Wipe all local ledger lists and accounts"),
                  onTap: () => _handleResetApp(provider),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8),
      ),
    );
  }
}
