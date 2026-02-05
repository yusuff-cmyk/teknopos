import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  TransactionProvider(this._apiService) {
    loadTransactions();
  }

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await DatabaseHelper.instance.getTransactions();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }

  double getTotalSales() {
    return _transactions.fold(0, (sum, t) => sum + t.totalAmount);
  }

  int getTransactionCount() {
    return _transactions.length;
  }
}
