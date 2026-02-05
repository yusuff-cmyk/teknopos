import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/voucher_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/mikrotik_service.dart';
import 'voucher_management_screen.dart';
import 'pos_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    PosScreen(),
    VoucherManagementScreen(),
    ReportsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showSettingsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final ipController = TextEditingController(
      text: prefs.getString('mikrotik_ip') ?? '',
    );
    final portController = TextEditingController(
      text: (prefs.getInt('mikrotik_port') ?? 8728).toString(),
    );
    final userController = TextEditingController(
      text: prefs.getString('mikrotik_user') ?? '',
    );
    final passController = TextEditingController(
      text: prefs.getString('mikrotik_password') ?? '',
    );

    String statusMessage = '';
    Color statusColor = Colors.grey;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Settings - Mikrotik'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP Address',
                      hintText: '192.168.88.1',
                    ),
                  ),
                  TextField(
                    controller: portController,
                    decoration: const InputDecoration(
                      labelText: 'API Port',
                      hintText: '8728',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'admin',
                    ),
                  ),
                  TextField(
                    controller: passController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            statusMessage = 'Testing connection...';
                            statusColor = Colors.orange;
                          });

                          final service = MikrotikService();
                          await service.saveSettings(
                            ipController.text,
                            int.tryParse(portController.text) ?? 8728,
                            userController.text,
                            passController.text,
                          );

                          bool connected = await service.testConnection();
                          setState(() {
                            statusMessage = connected
                                ? 'Connected Successfully!'
                                : 'Connection Failed';
                            statusColor = connected ? Colors.green : Colors.red;
                          });

                          if (connected && mounted) {
                            Provider.of<VoucherProvider>(
                              context,
                              listen: false,
                            ).loadVouchers();
                          }
                        },
                        child: const Text('Test & Save'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusMessage,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeknoPOS - WiFi Voucher Management System'),
        backgroundColor: Colors.blue[800],
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildNavItem(0, Icons.point_of_sale, 'POS'),
                _buildNavItem(1, Icons.inventory, 'Vouchers'),
                _buildNavItem(2, Icons.analytics, 'Reports'),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue[800] : Colors.grey[600],
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue[800] : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => _onItemTapped(index),
        dense: true,
      ),
    );
  }
}
