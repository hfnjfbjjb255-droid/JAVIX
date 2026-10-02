import 'package:flutter/services.dart';

/// Small native bridge for device data and Android runtime permissions.
/// It deliberately keeps the Flutter layer free of extra platform packages.
class JarvisPlatform {
  JarvisPlatform._();

  static const MethodChannel _channel = MethodChannel('jarvis/native');

  static Future<void> requestAllRelevantPermissions() async {
    await _channel.invokeMethod<void>('requestAllPermissions');
  }

  static Future<Map<String, bool>> permissionStatus() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('permissionStatus');
    return (result ?? const {}).map((key, value) => MapEntry(key.toString(), value == true));
  }

  static Future<int?> batteryPercent() async {
    return _channel.invokeMethod<int>('batteryPercent');
  }

  static Future<Map<String, double>?> location() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('location');
    if (result == null) return null;
    final lat = (result['latitude'] as num?)?.toDouble();
    final lon = (result['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return {'latitude': lat, 'longitude': lon};
  }
}
