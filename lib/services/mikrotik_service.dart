import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:async/async.dart';

class MikrotikService {
  String? _host;
  int? _port;
  String? _user;
  String? _password;

  MikrotikService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('mikrotik_ip');
    _port = prefs.getInt('mikrotik_port') ?? 8728;
    _user = prefs.getString('mikrotik_user');
    _password = prefs.getString('mikrotik_password');
  }

  Future<void> saveSettings(
    String ip,
    int port,
    String user,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mikrotik_ip', ip);
    await prefs.setInt('mikrotik_port', port);
    await prefs.setString('mikrotik_user', user);
    await prefs.setString('mikrotik_password', password);
    await _loadSettings();
  }

  Future<bool> testConnection() async {
    try {
      final users = await getUsers();
      return true;
    } catch (e) {
      print('Mikrotik Connection Error: $e');
      return false;
    }
  }

  Future<List<Map<String, String>>> getUsers() async {
    await _loadSettings();
    if (_host == null || _user == null) throw Exception('Settings not loaded');

    Socket socket = await Socket.connect(
      _host,
      _port!,
      timeout: const Duration(seconds: 5),
    );

    final reader = ChunkedStreamReader(socket);

    try {
      // Login (Modern method for RouterOS 6.43+)
      _send(socket, ['/login', '=name=$_user', '=password=$_password']);
      var response = await _readResponse(reader);
      if (response.contains('!trap')) throw Exception('Login failed');

      // Get Users
      _send(socket, ['/ip/hotspot/user/print']);
      return await _readBlocks(reader);
    } finally {
      reader.cancel();
      socket.destroy();
    }
  }

  Future<void> addUsersBulk(List<Map<String, String>> users) async {
    await _loadSettings();
    if (_host == null || _user == null) throw Exception('Settings not loaded');

    Socket socket = await Socket.connect(
      _host,
      _port!,
      timeout: const Duration(seconds: 30),
    );

    final reader = ChunkedStreamReader(socket);

    try {
      _send(socket, ['/login', '=name=$_user', '=password=$_password']);
      var response = await _readResponse(reader);
      if (response.contains('!trap')) throw Exception('Login failed');

      for (var user in users) {
        _send(socket, [
          '/ip/hotspot/user/add',
          '=name=${user['name']}',
          '=password=${user['password']}',
          '=profile=${user['profile']}',
          '=comment=${user['comment']}',
        ]);
        var res = await _readResponse(reader);
        if (res.contains('!trap')) throw Exception('Failed to add user: $res');
      }
    } finally {
      reader.cancel();
      socket.destroy();
    }
  }

  void _send(Socket socket, List<String> words) {
    for (var word in words) {
      _writeWord(socket, word);
    }
    _writeWord(socket, ''); // End of sentence
  }

  void _writeWord(Socket socket, String word) {
    var bytes = utf8.encode(word);
    var length = bytes.length;

    if (length < 0x80) {
      socket.add([length]);
    } else if (length < 0x4000) {
      socket.add([length ~/ 0x100 | 0x80, length % 0x100]);
    } else {
      // Handle larger lengths if necessary
      throw Exception('Word too long');
    }
    socket.add(bytes);
  }

  Future<List<String>> _readResponse(ChunkedStreamReader<int> reader) async {
    List<String> response = [];
    await for (var word in _readWords(reader)) {
      response.add(word);
      if (word == '!done') break;
    }
    return response;
  }

  Future<List<Map<String, String>>> _readBlocks(
    ChunkedStreamReader<int> reader,
  ) async {
    List<Map<String, String>> result = [];
    Map<String, String> currentBlock = {};

    await for (var word in _readWords(reader)) {
      if (word == '!re') {
        currentBlock = {};
        result.add(currentBlock);
      } else if (word == '!done') {
        break;
      } else if (word.startsWith('=')) {
        var parts = word.substring(1).split('=');
        if (parts.length >= 2) {
          var key = parts[0];
          var value = parts.sublist(1).join('=');
          if (result.isNotEmpty) {
            result.last[key] = value;
          }
        }
      }
    }
    return result;
  }

  Stream<String> _readWords(ChunkedStreamReader<int> reader) async* {
    while (true) {
      // Read length
      int length;
      var b = await reader.readBytes(1);
      if (b.isEmpty) break;
      int first = b[0];

      if ((first & 0x80) == 0) {
        length = first;
      } else if ((first & 0xC0) == 0x80) {
        var second = await reader.readBytes(1);
        length = ((first & 0x3F) << 8) | second[0];
      } else {
        // Simplified for standard responses
        length = 0;
      }

      if (length == 0) {
        // Empty word usually marks end of sentence, but in stream we yield empty string?
        // Actually API sends empty word to terminate sentence.
        // We can skip it or yield it.
        continue;
      }

      var bytes = await reader.readBytes(length);
      yield utf8.decode(bytes);
    }
  }
}
