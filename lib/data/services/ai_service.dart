import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiService extends ChangeNotifier {
  static const _baseKey = 'jarvis_ai_base_url';
  static const _keyKey = 'jarvis_ai_key';
  static const _imagePathKey = 'jarvis_ai_image_path';
  static const _videoPathKey = 'jarvis_ai_video_path';

  String _baseUrl = '';
  String _apiKey = '';
  String _imagePath = '/v1/images/generations';
  String _videoPath = '/v1/videos/generations';

  String get baseUrl => _baseUrl;
  String get imagePath => _imagePath;
  String get videoPath => _videoPath;
  bool get configured => _baseUrl.trim().isNotEmpty;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _baseUrl = p.getString(_baseKey) ?? '';
    _apiKey = p.getString(_keyKey) ?? '';
    _imagePath = p.getString(_imagePathKey) ?? _imagePath;
    _videoPath = p.getString(_videoPathKey) ?? _videoPath;
    notifyListeners();
  }

  Future<void> saveConfig({required String baseUrl, required String apiKey, required String imagePath, required String videoPath}) async {
    _baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/*$'), '');
    _apiKey = apiKey.trim();
    _imagePath = imagePath.trim().isEmpty ? '/v1/images/generations' : imagePath.trim();
    _videoPath = videoPath.trim().isEmpty ? '/v1/videos/generations' : videoPath.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString(_baseKey, _baseUrl);
    await p.setString(_keyKey, _apiKey);
    await p.setString(_imagePathKey, _imagePath);
    await p.setString(_videoPathKey, _videoPath);
    notifyListeners();
  }

  Future<String> generateImage(String prompt) => _generate(_imagePath, {
    'prompt': prompt,
    'size': '1024x1024',
  }, mediaKey: 'image');

  Future<String> generateVideo(String prompt) => _generate(_videoPath, {
    'prompt': prompt,
    'duration': 10,
    'seconds': 10,
    'aspect_ratio': '9:16',
  }, mediaKey: 'video');

  Future<String> _generate(String path, Map<String, dynamic> body, {required String mediaKey}) async {
    if (!configured) throw StateError('بوابة الذكاء الاصطناعي غير مهيأة بعد. افتح إعدادات المطور وأضف رابط الخدمة.');
    final uri = Uri.parse('$_baseUrl${path.startsWith('/') ? path : '/$path'}');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      if (_apiKey.isNotEmpty) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      request.write(jsonEncode(body));
      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('فشل توليد $mediaKey: HTTP ${response.statusCode}');
      }
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        final url = _findUrl(json);
        if (url != null) return url;
      }
      return raw;
    } finally {
      client.close(force: true);
    }
  }

  String? _findUrl(dynamic value) {
    if (value is Map) {
      for (final key in ['url', 'image_url', 'video_url', 'output_url']) {
        final v = value[key];
        if (v is String && v.startsWith('http')) return v;
      }
      for (final v in value.values) {
        final found = _findUrl(v);
        if (found != null) return found;
      }
    }
    if (value is List) {
      for (final v in value) {
        final found = _findUrl(v);
        if (found != null) return found;
      }
    }
    return null;
  }
}
