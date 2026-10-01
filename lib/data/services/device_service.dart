import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../core/constants.dart';
import '../../features/developer/logs/log_viewer_screen.dart';
import '../models/device.dart';

/// Controls smart home devices. Uses a local in-memory backend by default;
/// set [useMqtt] (Developer Edition) to drive a real broker.
class DeviceService extends ChangeNotifier {
  final List<Device> _devices = [
    Device(id: 'light.living', name: 'إضاءة الصالة', type: DeviceType.light, room: 'الصالة', isOn: true),
    Device(id: 'ac.bedroom', name: 'مكيف الغرفة', type: DeviceType.ac, room: 'الغرفة', level: 22),
    Device(id: 'tv.living', name: 'شاشة الصالة', type: DeviceType.tv, room: 'الصالة'),
  ];

  List<Device> get devices => List.unmodifiable(_devices);

  MqttServerClient? _client;
  bool _useMqtt = false;
  bool get useMqtt => _useMqtt;

  Future<void> connectMqtt({
    String? host,
    String? username,
    String? password,
    bool secure = false,
  }) async {
    final target = host ?? AppConstants.mqttDefaultHost;
    final port = secure ? 8883 : AppConstants.mqttDefaultPort;
    LogViewerScreen.log('mqtt: connecting to $target:$port secure=$secure');
    final client = MqttServerClient.withPort(
      target,
      'javix_${DateTime.now().millisecondsSinceEpoch}',
      port,
    );
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    client.secure = secure;
    final status = await client.connect(username, password);
    if (status?.state == MqttConnectionState.connected) {
      _client = client;
      _useMqtt = true;
      LogViewerScreen.log('mqtt: connected');
      notifyListeners();
    } else {
      client.disconnect();
      LogViewerScreen.log('mqtt: connection failed');
      throw StateError('تعذر الاتصال بوسيط MQTT');
    }
  }

  /// Execute a natural-language style command, e.g. "شغّل إضاءة الصالة".
  String runVoiceCommand(String command) {
    final cmd = _normalizeArabic(command);
    LogViewerScreen.log('voice command: $cmd');

    // Prefer an exact device name over a room name. This prevents
    // "شغل شاشة الصالة" from matching the first device in the room.
    final named = _devices.where((d) => cmd.contains(_normalizeArabic(d.name))).toList();
    final roomMatches = _devices.where((d) => cmd.contains(_normalizeArabic(d.room))).toList();
    final matches = named.isNotEmpty ? named : (roomMatches.length == 1 ? roomMatches : const <Device>[]);

    for (final d in matches) {
      if (cmd.contains('شغل') || cmd.contains('افتح') || cmd.contains('on')) {
        _apply(d, isOn: true);
        return 'تم تشغيل ${d.name}';
      }
      if (cmd.contains('طفي') ||
          cmd.contains('اطف') ||
          cmd.contains('وقف') ||
          cmd.contains('off')) {
        _apply(d, isOn: false);
        return 'تم إطفاء ${d.name}';
      }
    }
    return roomMatches.length > 1
        ? 'الأمر يطابق أكثر من جهاز، اذكر اسم الجهاز'
        : 'لم أفهم الأمر، حاول مرة أخرى';
  }

  String _normalizeArabic(String value) {
    return value
        .replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .toLowerCase()
        .trim();
  }

  void toggle(Device d) => _apply(d, isOn: !d.isOn);

  void setLevel(Device d, int level, {bool publish = true}) =>
      _apply(d, level: level, publish: publish);

  void _apply(Device d, {bool? isOn, int? level, bool publish = true}) {
    d.isOn = isOn ?? d.isOn;
    d.level = level ?? d.level;
    LogViewerScreen.log('device ${d.id}: on=${d.isOn} level=${d.level}');
    if (publish) _publish(d);
    notifyListeners();
  }

  void _publish(Device d) {
    final c = _client;
    if (c == null || !_useMqtt) return;
    final payload = '{"state":"${d.isOn ? "ON" : "OFF"}","level":${d.level}}';
    final builder = MqttClientPayloadBuilder()..addString(payload);
    c.publishMessage('javix/${d.id}/set', MqttQos.atLeastOnce, builder.payload!);
  }
}
