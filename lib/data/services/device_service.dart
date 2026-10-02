import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../core/constants.dart';
import '../../features/developer/logs/log_viewer_screen.dart';
import '../models/device.dart';

/// Real device layer. JARVIS never displays pretend devices.
/// Devices appear after the user configures them manually or an MQTT broker
/// publishes discovery records on `jarvis/discovery`.
class DeviceService extends ChangeNotifier {
  final List<Device> _devices = [];
  List<Device> get devices => List.unmodifiable(_devices);

  MqttServerClient? _client;
  bool _useMqtt = false;
  bool get useMqtt => _useMqtt;
  String? _broker;
  String? get broker => _broker;

  Future<void> connectMqtt({String? host, String? username, String? password, bool secure = false}) async {
    final target = (host ?? AppConstants.mqttDefaultHost).trim();
    final port = secure ? 8883 : AppConstants.mqttDefaultPort;
    final client = MqttServerClient.withPort(target, 'jarvis_${DateTime.now().millisecondsSinceEpoch}', port);
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    client.secure = secure;
    final status = await client.connect(username, password);
    if (status?.state != MqttConnectionState.connected) {
      client.disconnect();
      throw StateError('تعذر الاتصال بوسيط MQTT');
    }
    _client = client;
    _useMqtt = true;
    _broker = '$target:$port';
    client.subscribe('jarvis/discovery', MqttQos.atLeastOnce);
    client.updates?.listen(_handleMqttMessage);
    LogViewerScreen.log('mqtt: connected to $_broker');
    notifyListeners();
  }

  void _handleMqttMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final payload = event.payload as MqttPublishMessage;
      final raw = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) _addFromMap(data);
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) _addFromMap(item);
          }
        }
      } catch (_) {
        LogViewerScreen.log('mqtt: invalid discovery payload');
      }
    }
  }

  void _addFromMap(Map<String, dynamic> data) {
    final id = data['id']?.toString();
    final name = data['name']?.toString();
    if (id == null || name == null || id.isEmpty || name.isEmpty) return;
    final type = switch (data['type']?.toString().toLowerCase()) {
      'light' => DeviceType.light,
      'ac' => DeviceType.ac,
      'tv' => DeviceType.tv,
      _ => DeviceType.other,
    };
    final existing = _devices.indexWhere((d) => d.id == id);
    final device = Device(id: id, name: name, type: type, room: data['room']?.toString() ?? 'غير محدد', isOn: data['isOn'] == true, level: (data['level'] as num?)?.round() ?? 50);
    if (existing >= 0) _devices[existing] = device; else _devices.add(device);
    notifyListeners();
  }

  void addManualDevice({required String id, required String name, required DeviceType type, required String room}) {
    if (_devices.any((d) => d.id == id)) return;
    _devices.add(Device(id: id, name: name, type: type, room: room));
    notifyListeners();
  }

  String runVoiceCommand(String command) {
    final cmd = _normalizeArabic(command);
    LogViewerScreen.log('voice command: $cmd');
    if (_devices.isEmpty) return 'لا توجد أجهزة متصلة. أضف جهازاً أو اربط MQTT أولاً.';
    final named = _devices.where((d) => cmd.contains(_normalizeArabic(d.name))).toList();
    final roomMatches = _devices.where((d) => cmd.contains(_normalizeArabic(d.room))).toList();
    final matches = named.isNotEmpty ? named : (roomMatches.length == 1 ? roomMatches : const <Device>[]);
    for (final d in matches) {
      if (cmd.contains('شغل') || cmd.contains('افتح') || cmd.contains('on')) { _apply(d, isOn: true); return 'تم تشغيل ${d.name}'; }
      if (cmd.contains('طفي') || cmd.contains('اطف') || cmd.contains('وقف') || cmd.contains('off')) { _apply(d, isOn: false); return 'تم إطفاء ${d.name}'; }
    }
    return roomMatches.length > 1 ? 'الأمر يطابق أكثر من جهاز، اذكر اسم الجهاز' : 'لم أفهم الأمر، حاول مرة أخرى';
  }

  String _normalizeArabic(String value) => value.replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), '').replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ؤ', 'و').replaceAll('ئ', 'ي').toLowerCase().trim();

  void toggle(Device d) => _apply(d, isOn: !d.isOn);
  void setLevel(Device d, int level, {bool publish = true}) => _apply(d, level: level, publish: publish);

  void _apply(Device d, {bool? isOn, int? level, bool publish = true}) {
    d.isOn = isOn ?? d.isOn;
    d.level = level ?? d.level;
    if (publish) _publish(d);
    notifyListeners();
  }

  void _publish(Device d) {
    final c = _client;
    if (c == null || !_useMqtt) return;
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode({'state': d.isOn ? 'ON' : 'OFF', 'level': d.level}));
    c.publishMessage('jarvis/${d.id}/set', MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  void dispose() {
    _client?.disconnect();
    super.dispose();
  }
}
