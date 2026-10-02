import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_service.dart';

class AiService extends ChangeNotifier {
  static const _baseKey = 'jarvis_ai_base_url';
  static const _keyKey = 'jarvis_ai_key';
  static const _imagePathKey = 'jarvis_ai_image_path';
  static const _videoPathKey = 'jarvis_ai_video_path';
  static const _chatPathKey = 'jarvis_ai_chat_path';
  static const _modelKey = 'jarvis_ai_model';
  static const _usageDateKey = 'jarvis_usage_date';
  static const _imagesKey = 'jarvis_images_used';
  static const _videosKey = 'jarvis_videos_used';

  static const int freeImagesPerDay = 7;
  static const int freeVideosPerDay = 3;

  String _baseUrl = '';
  String _apiKey = '';
  String _imagePath = '/v1/images/generations';
  String _videoPath = '/v1/videos/generations';
  String _chatPath = '/v1/responses';
  String _model = 'gpt-5.6-luna';
  int _imagesUsed = 0;
  int _videosUsed = 0;

  String get baseUrl => _baseUrl;
  String get imagePath => _imagePath;
  String get videoPath => _videoPath;
  String get chatPath => _chatPath;
  String get model => _model;
  bool get configured => BackendService.instance.configured || _baseUrl.trim().isNotEmpty;
  bool get serverMode => BackendService.instance.configured;
  int get imagesUsed => _imagesUsed;
  int get videosUsed => _videosUsed;
  int get imagesRemaining => (freeImagesPerDay - _imagesUsed).clamp(0, freeImagesPerDay);
  int get videosRemaining => (freeVideosPerDay - _videosUsed).clamp(0, freeVideosPerDay);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _baseUrl = p.getString(_baseKey) ?? '';
    _apiKey = p.getString(_keyKey) ?? '';
    _imagePath = p.getString(_imagePathKey) ?? _imagePath;
    _videoPath = p.getString(_videoPathKey) ?? _videoPath;
    _chatPath = p.getString(_chatPathKey) ?? _chatPath;
    _model = p.getString(_modelKey) ?? _model;
    await _refreshUsage(p);
    notifyListeners();
  }

  Future<void> saveConfig({required String baseUrl, String? apiKey, required String imagePath, required String videoPath, String chatPath = '/v1/responses', String model = 'gpt-5.6-luna'}) async {
    _baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/*$'), '');
    if (apiKey != null && apiKey.trim().isNotEmpty) _apiKey = apiKey.trim();
    _imagePath = imagePath.trim().isEmpty ? '/v1/images/generations' : imagePath.trim();
    _videoPath = videoPath.trim().isEmpty ? '/v1/videos/generations' : videoPath.trim();
    _chatPath = chatPath.trim().isEmpty ? '/v1/responses' : chatPath.trim();
    _model = model.trim().isEmpty ? 'gpt-5.6-luna' : model.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString(_baseKey, _baseUrl);
    if (apiKey != null && apiKey.trim().isNotEmpty) await p.setString(_keyKey, _apiKey);
    await p.setString(_imagePathKey, _imagePath);
    await p.setString(_videoPathKey, _videoPath);
    await p.setString(_chatPathKey, _chatPath);
    await p.setString(_modelKey, _model);
    notifyListeners();
  }

  Future<String> chat(String prompt) async {
    if (BackendService.instance.configured) {
      final result = await BackendService.instance.post('/ai/chat', {'prompt': prompt});
      return _findText(result) ?? 'لم يصل نص من بوابة AI.';
    }
    if (_baseUrl.trim().isEmpty) throw StateError('خادم JARVIS غير مهيأ.');
    final result = await _post(_chatPath, {'model': _model, 'input': [{'role': 'user', 'content': [{'type': 'input_text', 'text': prompt}]}]});
    return _findText(result) ?? jsonEncode(result);
  }

  Future<String> generateImage(String prompt, {bool developer = false}) async {
    if (BackendService.instance.configured) {
      final result = await BackendService.instance.post('/ai/image', {'prompt': prompt, 'developer': developer});
      await _syncServerUsage(result);
      return _findUrl(result) ?? jsonEncode(result);
    }
    await _ensureUsageAllowed(video: false, developer: developer);
    final result = await _generate(_imagePath, {'model': 'gpt-image-2', 'prompt': prompt, 'size': '1024x1024'});
    await _consumeImage();
    return result;
  }

  Future<String> generateVideo(String prompt, {bool developer = false}) async {
    if (BackendService.instance.configured) {
      final result = await BackendService.instance.post('/ai/video', {'prompt': prompt, 'developer': developer, 'duration': 10});
      await _syncServerUsage(result);
      return _findUrl(result) ?? jsonEncode(result);
    }
    await _ensureUsageAllowed(video: true, developer: developer);
    final result = await _generate(_videoPath, {'prompt': prompt, 'duration': 10, 'seconds': 10, 'aspect_ratio': '9:16'});
    await _consumeVideo();
    return result;
  }

  Future<void> _syncServerUsage(Map<String, dynamic> result) async {
    final usage = result['usage'];
    if (usage is Map) {
      _imagesUsed = (usage['imagesUsed'] as num?)?.toInt() ?? _imagesUsed;
      _videosUsed = (usage['videosUsed'] as num?)?.toInt() ?? _videosUsed;
      notifyListeners();
    }
  }

  Future<void> _ensureUsageAllowed({required bool video, required bool developer}) async {
    if (developer) return;
    final p = await SharedPreferences.getInstance();
    await _refreshUsage(p);
    if ((video ? videosRemaining : imagesRemaining) <= 0) throw StateError(video ? 'وصلت إلى حد الفيديو المجاني اليوم: 3 فيديوهات.' : 'وصلت إلى حد الصور المجاني اليوم: 7 صور.');
  }

  Future<void> _refreshUsage(SharedPreferences p) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    if (p.getString(_usageDateKey) != key) {
      _imagesUsed = 0; _videosUsed = 0;
      await p.setString(_usageDateKey, key); await p.setInt(_imagesKey, 0); await p.setInt(_videosKey, 0); return;
    }
    _imagesUsed = p.getInt(_imagesKey) ?? 0; _videosUsed = p.getInt(_videosKey) ?? 0;
  }
  Future<void> _consumeImage() async { final p = await SharedPreferences.getInstance(); _imagesUsed++; await p.setInt(_imagesKey, _imagesUsed); notifyListeners(); }
  Future<void> _consumeVideo() async { final p = await SharedPreferences.getInstance(); _videosUsed++; await p.setInt(_videosKey, _videosUsed); notifyListeners(); }

  Future<String> _generate(String path, Map<String, dynamic> body) async { final json = await _post(path, body); return _findUrl(json) ?? jsonEncode(json); }
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl${path.startsWith('/') ? path : '/$path'}');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final request = await client.postUrl(uri); request.headers.contentType = ContentType.json; request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (_apiKey.isNotEmpty) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      request.write(jsonEncode(body)); final response = await request.close(); final raw = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) throw HttpException('فشل طلب JARVIS AI: HTTP ${response.statusCode}');
      final decoded = jsonDecode(raw); return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } finally { client.close(force: true); }
  }
  String? _findUrl(dynamic value) { if (value is Map) { for (final k in ['url','image_url','video_url','output_url']) { final v=value[k]; if (v is String && v.startsWith('http')) return v; } for (final v in value.values) { final x=_findUrl(v); if(x!=null)return x; } } if(value is List){for(final v in value){final x=_findUrl(v);if(x!=null)return x;}} return null; }
  String? _findText(dynamic value) { if(value is Map){ for(final k in ['output_text','text','content','message','response']){final v=value[k];if(v is String&&v.trim().isNotEmpty)return v;} for(final v in value.values){final x=_findText(v);if(x!=null)return x;} } if(value is List){for(final v in value){final x=_findText(v);if(x!=null)return x;}} return null; }
}
