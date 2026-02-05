import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'providers/voucher_provider.dart';
import 'providers/transaction_provider.dart';
import 'services/mikrotik_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('baseUrl') ?? 'http://192.168.1.50:8081';
  final authToken = prefs.getString('authToken') ?? 'your-license-key-here';

  final apiService = ApiService(baseUrl: baseUrl, authToken: authToken);
  final mikrotikService = MikrotikService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VoucherProvider(apiService, mikrotikService),
        ),
        ChangeNotifierProvider(create: (_) => TransactionProvider(apiService)),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeknoPOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
