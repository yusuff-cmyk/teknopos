import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import '../providers/voucher_provider.dart';
import '../models/voucher.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() =>
      _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  void _showAddVoucherDialog() {
    final voucherProvider = Provider.of<VoucherProvider>(
      context,
      listen: false,
    );
    final codeController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = voucherProvider.packets.isNotEmpty
        ? voucherProvider.packets.first.name
        : 'Default';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Voucher Manually'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Voucher Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: voucherProvider.packets.map((Packet packet) {
                    final category = packet.name;
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                      final packet = voucherProvider.packets.firstWhere(
                        (p) => p.name == newValue,
                        orElse: () => Packet(id: '', name: '', price: 0),
                      );
                      priceController.text = packet.price.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                final voucher = Voucher(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  code: codeController.text,
                  category: selectedCategory,
                  price: double.tryParse(priceController.text) ?? 0,
                  isSold: false,
                );

                await Provider.of<VoucherProvider>(
                  context,
                  listen: false,
                ).addVoucher(voucher);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voucher added successfully!'),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showGenerateVouchersDialog() {
    final voucherProvider = Provider.of<VoucherProvider>(
      context,
      listen: false,
    );
    final quantityController = TextEditingController(text: '10');
    final prefixController = TextEditingController();
    final lengthController = TextEditingController(text: '6');
    Packet? selectedPacket = voucherProvider.packets.isNotEmpty
        ? voucherProvider.packets.first
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Vouchers'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Packet>(
                    value: selectedPacket,
                    decoration: const InputDecoration(
                      labelText: 'Packet',
                      border: OutlineInputBorder(),
                    ),
                    items: voucherProvider.packets.map((Packet packet) {
                      return DropdownMenuItem<Packet>(
                        value: packet,
                        child: Text('${packet.name} - Rp ${packet.price}'),
                      );
                    }).toList(),
                    onChanged: (Packet? newValue) {
                      setState(() {
                        selectedPacket = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Prefix (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. WIFI-',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lengthController,
                    decoration: const InputDecoration(
                      labelText: 'Code Length',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedPacket != null &&
                  quantityController.text.isNotEmpty) {
                final quantity = int.parse(quantityController.text);
                final length = int.parse(lengthController.text);
                final prefix = prefixController.text;
                final List<Voucher> newVouchers = [];

                const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
                final rnd = Random();

                for (int i = 0; i < quantity; i++) {
                  final codeSuffix = List.generate(
                    length,
                    (index) => chars[rnd.nextInt(chars.length)],
                  ).join();
                  final code = '$prefix$codeSuffix';

                  newVouchers.add(
                    Voucher(
                      id:
                          DateTime.now().millisecondsSinceEpoch.toString() +
                          i.toString(),
                      code: code,
                      category: selectedPacket!.name,
                      price: selectedPacket!.price,
                      isSold: false,
                    ),
                  );
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating vouchers...')),
                );

                await voucherProvider.addVouchersBulk(newVouchers);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$quantity vouchers generated successfully!',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showManagePacketsDialog() {
    final voucherProvider = Provider.of<VoucherProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Packets'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<VoucherProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: provider.packets.length,
                itemBuilder: (context, index) {
                  final packet = provider.packets[index];
                  return ListTile(
                    title: Text(packet.name),
                    subtitle: Text('Rp ${packet.price}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditPacketDialog(packet),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.deletePacket(packet.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              final nameController = TextEditingController();
              final priceController = TextEditingController();
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Add Packet'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text;
                        final price = double.tryParse(priceController.text);

                        if (name.isNotEmpty && price != null) {
                          final packet = Packet(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: name,
                            price: price,
                          );
                          voucherProvider.addPacket(packet);
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Add New'),
          ),
        ],
      ),
    );
  }

  void _showEditPacketDialog(Packet packet) {
    final nameController = TextEditingController(text: packet.name);
    final priceController = TextEditingController(
      text: packet.price.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Packet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final price = double.tryParse(priceController.text);

              if (name.isNotEmpty && price != null) {
                final updatedPacket = Packet(
                  id: packet.id,
                  name: name,
                  price: price,
                );
                Provider.of<VoucherProvider>(context, listen: false)
                    .updatePacket(updatedPacket);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _importVouchers() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'rsc'],
    );

    if (result != null) {
      final file = result.files.first;
      final bytes = file.bytes!;
      final extension = file.extension?.toLowerCase() ?? '';

      final voucherProvider = Provider.of<VoucherProvider>(
        context,
        listen: false,
      );

      List<Voucher> newVouchers = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      try {
        if (extension == 'xlsx') {
          var excel = Excel.decodeBytes(bytes);
          for (var table in excel.tables.keys) {
            for (var row in excel.tables[table]!.rows.skip(1)) {
              if (row.length >= 2) {
                final code = row[0]?.value.toString() ?? '';
                final category = row[1]?.value.toString() ?? 'Default';
                double price = 0;
                if (row.length > 2) {
                  price = double.tryParse(row[2]?.value.toString() ?? '0') ?? 0;
                }

                if (price == 0) {
                  final packet = voucherProvider.packets.firstWhere(
                    (p) => p.name == category,
                    orElse: () => Packet(id: '', name: '', price: 0),
                  );
                  price = packet.price;
                }

                if (code.isNotEmpty) {
                  newVouchers.add(
                    Voucher(
                      id: '${timestamp}_${newVouchers.length}',
                      code: code,
                      category: category,
                      price: price,
                      isSold: false,
                    ),
                  );
                }
              }
            }
          }
        } else {
          final content = String.fromCharCodes(bytes);

          if (extension == 'rsc') {
            final lines = content.split('\n');
            for (final line in lines) {
              if (line.contains('name=')) {
                final nameMatch = RegExp(
                  r'name=(?:"([^"]+)"|([^\s]+))',
                ).firstMatch(line);
                final profileMatch = RegExp(
                  r'profile=(?:"([^"]+)"|([^\s]+))',
                ).firstMatch(line);

                if (nameMatch != null) {
                  final code = nameMatch.group(1) ?? nameMatch.group(2)!;
                  String category = voucherProvider.packets.isNotEmpty
                      ? voucherProvider.packets.first.name
                      : 'Default';

                  if (profileMatch != null) {
                    final profile =
                        profileMatch.group(1) ?? profileMatch.group(2)!;
                    if (voucherProvider.packets.any((p) => p.name == profile)) {
                      category = profile;
                    } else if (profile.toLowerCase().contains('jam')) {
                      category = '1 Jam';
                    } else if (profile.toLowerCase().contains('24') ||
                        profile.toLowerCase().contains('hari')) {
                      category = '24 Jam';
                    } else if (profile.toLowerCase().contains('minggu')) {
                      category = '1 Minggu';
                    } else if (profile.toLowerCase().contains('bulan')) {
                      category = '1 Bulan';
                    }
                  }

                  final packet = voucherProvider.packets.firstWhere(
                    (p) => p.name == category,
                    orElse: () => Packet(id: '', name: category, price: 0),
                  );
                  double price = packet.price;

                  newVouchers.add(
                    Voucher(
                      id: '${timestamp}_${newVouchers.length}',
                      code: code,
                      category: category,
                      price: price,
                      isSold: false,
                    ),
                  );
                }
              }
            }
          } else {
            // CSV
            final csvData = const CsvToListConverter().convert(content);
            for (final row in csvData.skip(1)) {
              if (row.length >= 2) {
                final code = row[0].toString();
                final category = row[1].toString();
                double price = 0;
                if (row.length > 2) {
                  price = double.tryParse(row[2].toString()) ?? 0;
                }

                if (price == 0) {
                  final packet = voucherProvider.packets.firstWhere(
                    (p) => p.name == category,
                    orElse: () => Packet(id: '', name: '', price: 0),
                  );
                  price = packet.price;
                }

                newVouchers.add(
                  Voucher(
                    id: '${timestamp}_${newVouchers.length}',
                    code: code,
                    category: category,
                    price: price,
                    isSold: false,
                  ),
                );
              }
            }
          }
        }

        if (newVouchers.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Importing vouchers...')),
          );
          await voucherProvider.addVouchersBulk(newVouchers);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${newVouchers.length} vouchers imported successfully!',
                ),
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No vouchers found in file')),
            );
          }
        }
      } catch (e) {
        print('Error importing: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error importing file: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoucherProvider>(
      builder: (context, voucherProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Text(
                    'Voucher Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh / Sync Mikrotik',
                    onPressed: () {
                      Provider.of<VoucherProvider>(
                        context,
                        listen: false,
                      ).loadVouchers();
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showManagePacketsDialog,
                    icon: const Icon(Icons.settings),
                    label: const Text('Packets'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _showGenerateVouchersDialog,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddVoucherDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Manual'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _importVouchers,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: voucherProvider.packets.length,
                itemBuilder: (context, index) {
                  final packet = voucherProvider.packets[index];
                  final vouchers = voucherProvider.getAvailableVouchers(
                    packet.name,
                  );
                  final soldVouchers = voucherProvider.vouchers
                      .where((v) => v.category == packet.name && v.isSold)
                      .toList();

                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                color: Colors.blue[600],
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                packet.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatCard(
                                'Available',
                                vouchers.length,
                                Colors.green,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                'Sold',
                                soldVouchers.length,
                                Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: [
                                ...vouchers
                                    .take(3)
                                    .map(
                                      (voucher) => ListTile(
                                        dense: true,
                                        title: Text(
                                          voucher.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Rp ${voucher.price.toStringAsFixed(0)}',
                                        ),
                                        trailing: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                if (vouchers.length > 3)
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '... and more',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
