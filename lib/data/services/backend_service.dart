import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class BackendService extends ChangeNotifier {
  static final BackendService instance = BackendService._();
  BackendService._();
  static const _tokenKey = 'jarvis_backend_token';
  String _token = '';
  String _baseUrl = AppConstants.backendUrl;

  String get baseUrl => _baseUrl;
  String get token => _token;
  bool get configured => _baseUrl.trim().isNotEmpty;
  bool get authenticated => _token.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferencesCompat.instance();
    _token = prefs.getString(_tokenKey) ?? '';
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceFirst(RegExp(r'/*$'), '');
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token.trim();
    final prefs = await SharedPreferencesCompat.instance();
    if (_token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, _token);
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    if (!configured) throw StateError('خادم JARVIS غير مهيأ. أضف JARVIS_BACKEND_URL عند البناء.');
    final uri = Uri.parse('$_baseUrl${path.startsWith('/') ? path : '/$path'}');
    final headers = <String, String>{'content-type': 'application/json', 'accept': 'application/json'};
    if (auth && _token.isNotEmpty) headers['authorization'] = 'Bearer $_token';
    final response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 45));
    return _decode(response);
  }

  Future<bool> ping() async {
    if (!configured) return false;
    try {
      await get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    if (!configured) throw StateError('خادم JARVIS غير مهيأ.');
    final uri = Uri.parse('$_baseUrl${path.startsWith('/') ? path : '/$path'}');
    final headers = <String, String>{'accept': 'application/json'};
    if (_token.isNotEmpty) headers['authorization'] = 'Bearer $_token';
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try { decoded = jsonDecode(response.body); } catch (_) { decoded = {'message': response.body}; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? (decoded['message'] ?? decoded['error'] ?? 'HTTP ${response.statusCode}') : 'HTTP ${response.statusCode}';
      throw StateError(message.toString());
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }
}

// Kept tiny so backend auth can share the same persistence without another
// package-level singleton. It wraps SharedPreferences lazily.
class SharedPreferencesCompat {
  SharedPreferencesCompat._(this.prefs);
  final dynamic prefs;
  static Future<SharedPreferencesCompat> instance() async {
    final p = await SharedPreferences.getInstance();
    return SharedPreferencesCompat._(p);
  }
  String? getString(String key) => prefs.getString(key);
  Future<void> setString(String key, String value) => prefs.setString(key, value);
  Future<void> remove(String key) => prefs.remove(key);
}
