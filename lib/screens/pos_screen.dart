import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voucher_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/voucher.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<Voucher> _selectedVouchers = [];
  String _paymentMethod = 'Cash';

  void _addVoucherToCart(Voucher voucher) {
    setState(() {
      _selectedVouchers.add(voucher);
    });
  }

  void _removeVoucherFromCart(Voucher voucher) {
    setState(() {
      _selectedVouchers.remove(voucher);
    });
  }

  double _calculateTotal() {
    return _selectedVouchers.fold(0, (sum, voucher) => sum + voucher.price);
  }

  void _checkout() async {
    if (_selectedVouchers.isEmpty) return;

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      voucherIds: _selectedVouchers.map((v) => v.id).toList(),
      totalAmount: _calculateTotal(),
      timestamp: DateTime.now(),
      paymentMethod: _paymentMethod,
    );

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final voucherProvider = Provider.of<VoucherProvider>(
      context,
      listen: false,
    );

    await transactionProvider.addTransaction(transaction);

    await voucherProvider.sellVouchersBulk(
      _selectedVouchers.map((v) => v.id).toList(),
    );

    setState(() {
      _selectedVouchers.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction completed successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoucherProvider>(
      builder: (context, voucherProvider, child) {
        return Row(
          children: [
            // Product Selection Area
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Select Voucher Package',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: voucherProvider.packets.length,
                      itemBuilder: (context, index) {
                        final packet = voucherProvider.packets[index];
                        final allAvailableVouchers = voucherProvider
                            .getAvailableVouchers(packet.name);

                        // Filter out vouchers that are already in the cart
                        final cartVoucherIds = _selectedVouchers
                            .map((v) => v.id)
                            .toSet();
                        final availableVouchers = allAvailableVouchers
                            .where((v) => !cartVoucherIds.contains(v.id))
                            .toList();
                        final stockCount = availableVouchers.length;

                        return Card(
                          elevation: 4,
                          child: InkWell(
                            onTap: stockCount > 0
                                ? () {
                                    if (availableVouchers.isNotEmpty) {
                                      _addVoucherToCart(
                                        availableVouchers.first,
                                      );
                                    }
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: stockCount > 0
                                    ? Colors.green[50]
                                    : Colors.grey[100],
                                border: Border.all(
                                  color: stockCount > 0
                                      ? Colors.green
                                      : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.wifi,
                                    size: 48,
                                    color: stockCount > 0
                                        ? Colors.green[700]
                                        : Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    packet.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: stockCount > 0
                                          ? Colors.green[800]
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Stock: $stockCount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: stockCount > 0
                                          ? Colors.green[600]
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Cart and Checkout Area
            Container(
              width: 400,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue[50],
                    child: const Row(
                      children: [
                        Icon(Icons.shopping_cart, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Cart',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _selectedVouchers.isEmpty
                        ? const Center(
                            child: Text(
                              'No items in cart',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _selectedVouchers.length,
                            itemBuilder: (context, index) {
                              final voucher = _selectedVouchers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    voucher.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('${voucher.category}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Rp ${voucher.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removeVoucherFromCart(voucher),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp ${_calculateTotal().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Cash', 'Transfer', 'E-Wallet'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _paymentMethod = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _selectedVouchers.isNotEmpty
                                ? _checkout
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Complete Sale (F12)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
