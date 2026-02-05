import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/voucher_provider.dart';
import '../models/transaction.dart';
import '../models/voucher.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> _exportToExcel(
    BuildContext context,
    List<Transaction> transactions,
  ) async {
    final voucherProvider = Provider.of<VoucherProvider>(
      context,
      listen: false,
    );

    var excel = Excel.createExcel();

    // Rename default sheet
    String defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, 'Transactions');

    // Sheet 1: Transactions
    Sheet sheet1 = excel['Transactions'];
    sheet1.appendRow([
      TextCellValue('ID'),
      TextCellValue('Date'),
      TextCellValue('Total Amount'),
      TextCellValue('Payment Method'),
      TextCellValue('Voucher Count'),
    ]);

    for (var t in transactions) {
      sheet1.appendRow([
        TextCellValue(t.id),
        TextCellValue(t.timestamp.toString()),
        DoubleCellValue(t.totalAmount),
        TextCellValue(t.paymentMethod),
        IntCellValue(t.voucherIds.length),
      ]);
    }

    // Sheet 2: Stock
    Sheet sheet2 = excel['Stock'];
    sheet2.appendRow([
      TextCellValue('Category'),
      TextCellValue('Available Stock'),
    ]);

    for (var p in voucherProvider.packets) {
      sheet2.appendRow([
        TextCellValue(p.name),
        IntCellValue(voucherProvider.getStockCount(p.name)),
      ]);
    }

    var fileBytes = excel.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/teknopos_report.xlsx');
    await file.writeAsBytes(fileBytes!);

    // Share the file
    await Share.shareXFiles([XFile(file.path)], text: 'TeknoPOS Report');
  }

  void _showRefundDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${transaction.id}'),
            Text(
              'Date: ${DateFormat('dd MMM yyyy HH:mm').format(transaction.timestamp)}',
            ),
            Text('Amount: Rp ${transaction.totalAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            const Text(
              'Vouchers:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              width: double.maxFinite,
              child: Consumer<VoucherProvider>(
                builder: (context, voucherProvider, child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: transaction.voucherIds.length,
                    itemBuilder: (context, index) {
                      final voucherId = transaction.voucherIds[index];
                      final voucher = voucherProvider.vouchers.firstWhere(
                        (v) => v.id == voucherId,
                        orElse:
                            () => Voucher(
                              id: voucherId,
                              code: 'Unknown',
                              category: '-',
                              price: 0,
                              isSold: true,
                            ),
                      );
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(voucher.code),
                        subtitle: Text(voucher.category),
                        trailing: Text('Rp ${voucher.price.toStringAsFixed(0)}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirm Refund'),
                      content: const Text(
                        'Are you sure you want to refund this transaction? '
                        'Vouchers will be returned to stock.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Refund'),
                        ),
                      ],
                    ),
              );

              if (confirm == true && context.mounted) {
                final transactionProvider = Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                );
                final voucherProvider = Provider.of<VoucherProvider>(
                  context,
                  listen: false,
                );

                // 1. Return vouchers to stock
                await voucherProvider.refundVouchersBulk(
                  transaction.voucherIds,
                );

                // 2. Delete transaction
                await transactionProvider.deleteTransaction(transaction.id);

                if (context.mounted) {
                  Navigator.pop(context); // Close detail dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction refunded successfully'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore),
            label: const Text('Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, VoucherProvider>(
      builder: (context, transactionProvider, voucherProvider, child) {
        // Filter transactions
        final filteredTransactions = transactionProvider.transactions.where((
          t,
        ) {
          if (_selectedDateRange == null) return true;
          final start = _selectedDateRange!.start;
          final end = _selectedDateRange!.end.add(const Duration(days: 1));
          return t.timestamp.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              t.timestamp.isBefore(end);
        }).toList();

        // Sort descending by date
        filteredTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final totalSales = filteredTransactions.fold(
          0.0,
          (sum, t) => sum + t.totalAmount,
        );
        final transactionCount = filteredTransactions.length;

        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        final dateFormat = DateFormat('dd MMM yyyy');

        // Calculate payment method stats
        Map<String, double> paymentStats = {};
        for (var t in filteredTransactions) {
          paymentStats[t.paymentMethod] =
              (paymentStats[t.paymentMethod] ?? 0) + t.totalAmount;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sales Reports',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _exportToExcel(context, filteredTransactions),
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date Filter
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDateRange == null
                        ? 'All Time'
                        : '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _selectedDateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDateRange = picked;
                        });
                      }
                    },
                    child: const Text('Change Date'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Sales',
                      currencyFormat.format(totalSales),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Transactions',
                      transactionCount.toString(),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Methods
              const Text(
                'Sales by Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (paymentStats.isEmpty)
                const Text(
                  'No sales yet.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...paymentStats.entries.map(
                  (e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.payment),
                      title: Text(e.key),
                      trailing: Text(
                        currencyFormat.format(e.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Stock Summary
              const Text(
                'Stock Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (voucherProvider.packets.isEmpty)
                const Text(
                  'No packets defined.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...voucherProvider.packets.map((packet) {
                  final stock = voucherProvider.getStockCount(packet.name);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.wifi),
                      title: Text(packet.name),
                      subtitle: Text(currencyFormat.format(packet.price)),
                      trailing: Chip(
                        label: Text('$stock available'),
                        backgroundColor: stock > 0
                            ? Colors.green[100]
                            : Colors.red[100],
                        labelStyle: TextStyle(
                          color: stock > 0
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Recent Transactions
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (filteredTransactions.isEmpty)
                const Text(
                  'No transactions found for selected period.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final t = filteredTransactions[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _showRefundDialog(context, t),
                        title: Text('ID: ${t.id.substring(0, 8)}...'),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy HH:mm').format(t.timestamp),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(t.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              t.paymentMethod,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
