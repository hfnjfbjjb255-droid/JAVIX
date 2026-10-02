import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/platform/jarvis_platform.dart';
import '../../features/developer/logs/log_viewer_screen.dart';

class DeviceStatusService extends ChangeNotifier {
  int? _battery;
  Map<String, double>? _location;
  String _weatherText = 'جارِ جلب الطقس الحقيقي...';
  double? _temperature;
  String _place = 'الموقع الحالي';
  bool _loadingWeather = false;
  String _locationMessage = 'جاري تحديد الموقع...';
  Timer? _timer;

  int? get battery => _battery;
  Map<String, double>? get location => _location;
  String get weatherText => _weatherText;
  double? get temperature => _temperature;
  String get place => _place;
  bool get loadingWeather => _loadingWeather;
  String get locationMessage => _locationMessage;

  Future<void> start() async {
    await refresh();
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      _battery = await JarvisPlatform.batteryPercent();
      _location = await JarvisPlatform.location();
      _locationMessage = _location == null
          ? 'تعذر تحديد الموقع. تأكد من تشغيل خدمة الموقع في Android ثم أعد المحاولة.'
          : 'تم تحديد الموقع بنجاح.';
      notifyListeners();
      if (_location != null) {
        await _loadWeather(_location!);
      }
    } catch (e) {
      LogViewerScreen.log('device status refresh failed: $e');
    }
    notifyListeners();
  }

  Future<void> _loadWeather(Map<String, double> location) async {
    if (_loadingWeather) return;
    _loadingWeather = true;
    notifyListeners();
    final lat = location['latitude']!;
    final lon = location['longitude']!;
    try {
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto',
      );
      final weather = await _getJson(weatherUri);
      final current = weather['current'] as Map<String, dynamic>?;
      _temperature = (current?['temperature_2m'] as num?)?.toDouble();
      _weatherText = _weatherDescription((current?['weather_code'] as num?)?.toInt());
      final place = await _reverseGeocode(lat, lon);
      if (place != null && place.trim().isNotEmpty) _place = place.trim();
    } catch (e) {
      _weatherText = 'تعذر جلب الطقس حالياً';
      LogViewerScreen.log('weather failed: $e');
    } finally {
      _loadingWeather = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=10&accept-language=ar',
    );
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'JARVIS Android Assistant/1.0');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close(force: true);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      return (address?['city'] ?? address?['town'] ?? address?['municipality'] ?? address?['county'])?.toString();
    } catch (_) {
      return null;
    }
  }

  String _weatherDescription(int? code) {
    switch (code) {
      case 0: return 'صافي';
      case 1:
      case 2: return 'غائم جزئياً';
      case 3: return 'غائم';
      case 45:
      case 48: return 'ضباب';
      case 51:
      case 53:
      case 55: return 'رذاذ';
      case 61:
      case 63:
      case 65: return 'مطر';
      case 71:
      case 73:
      case 75: return 'ثلوج';
      case 80:
      case 81:
      case 82: return 'زخات مطر';
      case 95: return 'عاصفة رعدية';
      case 96:
      case 99: return 'عاصفة رعدية وبَرَد';
      default: return 'حالة جوية غير معروفة';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
