import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/expense.dart';
import '../models/income.dart';

class PdfHelper {
  static Future<File> generateLedgerPdf({
    required Customer customer,
    required List<TransactionModel> transactions,
    required double totalGive,
    required double totalTake,
    required double netBalance,
    required String currency,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final netText = netBalance > 0 
        ? "Customer owes you: $currency${netBalance.abs().toStringAsFixed(2)}" 
        : netBalance < 0 
            ? "You owe customer: $currency${netBalance.abs().toStringAsFixed(2)}"
            : "Settle (0.00)";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Business Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "KHATA BOOK STATEMENT",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("Date Generated: $dateStr", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Khata Ledger App", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Your Digital Account Book", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Customer Summary Panel
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            customer.name,
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text("Phone: ${customer.phone}", style: const pw.TextStyle(fontSize: 11)),
                          pw.Text("Purpose: ${customer.paymentPurpose}", style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            "Net Balance",
                            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            netText,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: netBalance > 0 
                                  ? PdfColors.green 
                                  : netBalance < 0 
                                      ? PdfColors.red 
                                      : PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text("TOTAL GIVEN", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text("$currency${totalGive.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text("TOTAL TAKEN", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text("$currency${totalTake.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Ledger Title
            pw.Text(
              "TRANSACTION ENTRIES",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            // Table of Transactions
            pw.Table(
              border: pw.TableBorder.symmetric(
                inside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                outside: const pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3), // Date
                1: pw.FlexColumnWidth(4), // Description
                2: pw.FlexColumnWidth(2), // Type
                3: pw.FlexColumnWidth(3), // Amount
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Date & Time", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Note / Remarks", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Type", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Amount ($currency)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                // Table Entries
                ...transactions.map((item) {
                  final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(item.date);
                  final isGive = item.type == 'give';
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.description.isEmpty ? '-' : item.description,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          isGive ? "GIVE" : "TAKE",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: isGive ? PdfColors.red : PdfColors.green,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.price.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: isGive ? PdfColors.red : PdfColors.green,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 30),

            // Footer Signature section
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 120,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text("Authorized Signature", style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Save report to temporary dir
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, '${customer.name.replaceAll(' ', '_')}_ledger_statement.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateMonthlyReportPdf({
    required DateTime selectedMonth,
    required List<Expense> expenses,
    required List<Income> incomes,
    required double totalIncome,
    required double totalExpenses,
    required double netBalance,
    required String currency,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final monthStr = DateFormat('MMMM yyyy').format(selectedMonth);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Business Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "INCOME & EXPENSE LEDGER",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("Statement Period: $monthStr", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text("Generated on: $dateStr", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Personal Ledger App", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Income & Expense Statement", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // Summary Panel
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Monthly Summary",
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            "Net Balance: ",
                            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            "$currency${netBalance.toStringAsFixed(2)}",
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: netBalance >= 0 ? PdfColors.green : PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text("TOTAL MONTHLY INCOME", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text("$currency${totalIncome.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text("TOTAL MONTHLY EXPENSES", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text("$currency${totalExpenses.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Incomes Section
            pw.Text(
              "INCOME LOGS",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
            ),
            pw.SizedBox(height: 6),
            if (incomes.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text("No income records found for this month.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              )
            else
              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  outside: const pw.BorderSide(color: PdfColors.grey300, width: 1),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3), // Date
                  1: pw.FlexColumnWidth(4), // Description
                  2: pw.FlexColumnWidth(3), // Category
                  3: pw.FlexColumnWidth(3), // Amount
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Date", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Income Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Category", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Amount ($currency)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...incomes.map((item) {
                    final formattedDate = DateFormat('dd MMM yyyy').format(item.date);
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.title, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.category, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.amount.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 20),

            // Expenses Section
            pw.Text(
              "EXPENSE LOGS",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
            ),
            pw.SizedBox(height: 6),
            if (expenses.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text("No expense records found for this month.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              )
            else
              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  outside: const pw.BorderSide(color: PdfColors.grey300, width: 1),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3), // Date
                  1: pw.FlexColumnWidth(4), // Description
                  2: pw.FlexColumnWidth(3), // Category
                  3: pw.FlexColumnWidth(3), // Amount
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Date", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Expense Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Category", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Amount ($currency)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...expenses.map((item) {
                    final formattedDate = DateFormat('dd MMM yyyy').format(item.date);
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.title, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.category, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.amount.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.red), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    // Save report to temporary dir
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'income_expense_report_${DateFormat('MMM_yyyy').format(selectedMonth)}.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
