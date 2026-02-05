import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher.dart';
import '../models/transaction.dart';

class ApiService {
  final String baseUrl;
  final String authToken;

  ApiService({required this.baseUrl, required this.authToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Auth-Token': authToken,
  };

  Future<List<Voucher>> getVouchers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/db/vouchers'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Voucher.fromJson(json['data'])).toList();
    } else {
      throw Exception('Failed to load vouchers');
    }
  }

  Future<void> saveVoucher(Voucher voucher) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/db/vouchers'),
      headers: _headers,
      body: json.encode(voucher.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save voucher');
    }
  }

  Future<void> updateVoucher(String id, Voucher voucher) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/db/vouchers/$id'),
      headers: _headers,
      body: json.encode(voucher.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update voucher');
    }
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/db/transactions'),
      headers: _headers,
      body: json.encode(transaction.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save transaction');
    }
  }

  Future<List<Transaction>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/db/transactions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Transaction.fromJson(json['data'])).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<List<Packet>> getPackets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/db/packets'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Packet.fromJson(json['data'])).toList();
    } else {
      return [];
    }
  }

  Future<void> savePacket(Packet packet) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/db/packets'),
      headers: _headers,
      body: json.encode(packet.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save packet');
    }
  }

  Future<void> deletePacket(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/api/db/packets/$id'),
      headers: _headers,
    );
  }
}
