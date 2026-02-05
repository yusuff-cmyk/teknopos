import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/mikrotik_service.dart';

class VoucherProvider with ChangeNotifier {
  final ApiService _apiService;
  final MikrotikService _mikrotikService;
  List<Voucher> _vouchers = [];
  List<Packet> _packets = [];
  bool _isLoading = false;

  VoucherProvider(this._apiService, this._mikrotikService) {
    _init();
  }

  Future<void> _init() async {
    await loadPackets();
    await loadVouchers();
  }

  List<Voucher> get vouchers => _vouchers;
  List<Packet> get packets => _packets;
  bool get isLoading => _isLoading;

  Future<void> loadVouchers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load Local Data first to know what is already sold
      final localVouchers = await DatabaseHelper.instance.getVouchers();
      _vouchers = localVouchers;

      // Create a set of sold voucher codes for fast lookup
      final soldVoucherCodes = localVouchers
          .where((v) => v.isSold)
          .map((v) => v.code)
          .toSet();

      // Try to sync with Mikrotik if configured
      try {
        final mikrotikUsers = await _mikrotikService.getUsers();
        if (mikrotikUsers.isNotEmpty) {
          // Convert Mikrotik users to Vouchers
          List<Voucher> mikrotikVouchers = [];
          Set<String> mikrotikProfiles = {};

          for (var user in mikrotikUsers) {
            final uptime = user['uptime'];

            // Only include users that have never been used (uptime is null)
            // or have had their counters reset (uptime is '0s').
            if (uptime == null || uptime == '0s') {
              final name = user['name'] ?? '';
              if (name.isEmpty) continue;

              final profile = user['profile'] ?? 'Default';
              mikrotikProfiles.add(profile);

              // Find price from packets
              final packet = _packets.firstWhere(
                (p) => p.name == profile,
                orElse: () => Packet(id: '0', name: profile, price: 0),
              );

              // Check if this voucher is already sold locally
              final isSoldLocally = soldVoucherCodes.contains(name);

              mikrotikVouchers.add(
                Voucher(
                  id: 'mikrotik_$name',
                  code: name,
                  category: profile,
                  price: packet.price,
                  // If sold locally, mark as sold. Otherwise, trust Mikrotik (false)
                  isSold: isSoldLocally,
                ),
              );
            }
          }

          // Add missing profiles to packets list for UI display
          for (var profile in mikrotikProfiles) {
            if (!_packets.any((p) => p.name == profile)) {
              _packets.add(
                Packet(id: 'mt_${profile.hashCode}', name: profile, price: 0),
              );
            }
          }

          // Replace local vouchers with Mikrotik ones for display
          _vouchers = mikrotikVouchers;
        }
      } catch (e) {
        // Mikrotik sync failed or not configured, stick to DB
        print('Mikrotik sync skipped: $e');
      }
    } catch (e) {
      // Handle error
      print('Error loading vouchers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPackets() async {
    try {
      _packets = await DatabaseHelper.instance.getPackets();
      if (_packets.isEmpty) {
        _packets = [Packet(id: '1', name: '1 Jam', price: 2000)];
        for (var p in _packets) {
          await DatabaseHelper.instance.insertPacket(p);
        }
      }
    } catch (e) {
      print('Error loading packets: $e');
    }
    notifyListeners();
  }

  Future<void> addPacket(Packet packet) async {
    await DatabaseHelper.instance.insertPacket(packet);
    await loadPackets();
  }

  Future<void> updatePacket(Packet packet) async {
    // Use insertPacket to handle upsert (update if exists, insert if not)
    // This handles Mikrotik profiles that are only in memory initially
    await DatabaseHelper.instance.insertPacket(packet);
    // Reload both packets and vouchers to ensure prices are synced everywhere
    await loadPackets();
    await loadVouchers();
  }

  Future<void> deletePacket(String id) async {
    await DatabaseHelper.instance.deletePacket(id);
    await loadPackets();
  }

  Future<void> addVoucher(Voucher voucher) async {
    await DatabaseHelper.instance.insertVoucher(voucher);
    await loadVouchers();
  }

  Future<void> addVouchersBulk(List<Voucher> vouchers) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Add to Mikrotik
      final batchComment =
          'GEN_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

      List<Map<String, String>> mikrotikUsers = vouchers.map((v) {
        return {
          'name': v.code,
          'password': v.code, // Default: password same as code
          'profile': v.category,
          'comment': batchComment,
        };
      }).toList();

      try {
        await _mikrotikService.addUsersBulk(mikrotikUsers);
      } catch (e) {
        print('Failed to add to Mikrotik: $e');
        rethrow; // Stop process if Mikrotik fails
      }

      await DatabaseHelper.instance.insertVouchersBulk(vouchers);
      await loadVouchers();
    } catch (e) {
      print('Error bulk adding vouchers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVoucher(Voucher voucher) async {
    await DatabaseHelper.instance.updateVoucher(voucher);
    await loadVouchers();
  }

  Future<void> sellVoucher(String voucherId) async {
    final voucher = _vouchers.firstWhere((v) => v.id == voucherId);
    final updatedVoucher = Voucher(
      id: voucher.id,
      code: voucher.code,
      category: voucher.category,
      price: voucher.price,
      isSold: true,
      soldAt: DateTime.now(),
    );
    await updateVoucher(updatedVoucher);
  }

  Future<void> sellVouchersBulk(List<String> voucherIds) async {
    for (final id in voucherIds) {
      try {
        final voucher = _vouchers.firstWhere((v) => v.id == id);
        final updatedVoucher = Voucher(
          id: voucher.id,
          code: voucher.code,
          category: voucher.category,
          price: voucher.price,
          isSold: true,
          soldAt: DateTime.now(),
        );
        // Use insertVoucher (which uses ConflictAlgorithm.replace)
        // because the voucher might be from Mikrotik and not exist in DB yet.
        await DatabaseHelper.instance.insertVoucher(updatedVoucher);
      } catch (e) {
        print('Error selling voucher $id: $e');
      }
    }
    await loadVouchers();
  }

  Future<void> refundVouchersBulk(List<String> voucherIds) async {
    for (final id in voucherIds) {
      try {
        final voucher = _vouchers.firstWhere((v) => v.id == id);
        final updatedVoucher = Voucher(
          id: voucher.id,
          code: voucher.code,
          category: voucher.category,
          price: voucher.price,
          isSold: false,
          soldAt: null,
        );
        await DatabaseHelper.instance.updateVoucher(updatedVoucher);
      } catch (e) {
        print('Error refunding voucher $id: $e');
      }
    }
    await loadVouchers();
  }

  List<Voucher> getAvailableVouchers(String category) {
    return _vouchers.where((v) => v.category == category && !v.isSold).toList();
  }

  int getStockCount(String category) {
    return getAvailableVouchers(category).length;
  }
}
