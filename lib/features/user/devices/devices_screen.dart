import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/strings_ar.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/models/device.dart';
import '../../../data/services/device_service.dart';
import '../../../widgets/gold_card.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  IconData _icon(DeviceType t) => switch (t) { DeviceType.light => Icons.lightbulb_outline, DeviceType.ac => Icons.ac_unit, DeviceType.tv => Icons.tv, DeviceType.other => Icons.devices_other };
  double _min(Device d) => d.type == DeviceType.ac ? 16 : 0;
  double _max(Device d) => d.type == DeviceType.ac ? 30 : 100;
  String _levelLabel(Device d) => switch (d.type) { DeviceType.light => 'السطوع ${d.level}٪', DeviceType.ac => 'الحرارة ${d.level}°', DeviceType.tv => 'الصوت ${d.level}٪', DeviceType.other => 'المستوى ${d.level}٪' };

  Future<void> _mqttDialog() async {
    final host = TextEditingController(); final user = TextEditingController(); final pass = TextEditingController();
    try {
      await showDialog(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('ربط MQTT'),
        content: SingleChildScrollView(child: Column(children: [TextField(controller: host, decoration: const InputDecoration(labelText: 'عنوان الخادم')), TextField(controller: user, decoration: const InputDecoration(labelText: 'اسم المستخدم')), TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور'))])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async { try { await context.read<DeviceService>().connectMqtt(host: host.text.isEmpty ? null : host.text, username: user.text.isEmpty ? null : user.text, password: pass.text.isEmpty ? null : pass.text); if (dialogContext.mounted) Navigator.pop(dialogContext); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاتصال بـ MQTT. بانتظار اكتشاف الأجهزة.'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }, child: const Text('اتصال'))],
      ));
    } finally { host.dispose(); user.dispose(); pass.dispose(); }
  }

  Future<void> _manualDevice() async {
    final id = TextEditingController(); final name = TextEditingController(); final room = TextEditingController(); DeviceType type = DeviceType.other;
    try {
      await showDialog(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
        title: const Text('إضافة جهاز حقيقي'),
        content: SingleChildScrollView(child: Column(children: [TextField(controller: id, decoration: const InputDecoration(labelText: 'معرّف الجهاز / MQTT topic')), TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الجهاز')), TextField(controller: room, decoration: const InputDecoration(labelText: 'الغرفة')), DropdownButtonFormField<DeviceType>(value: type, items: DeviceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(), onChanged: (v) => setDialog(() => type = v ?? DeviceType.other), decoration: const InputDecoration(labelText: 'النوع'))])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () { if (id.text.trim().isEmpty || name.text.trim().isEmpty) return; context.read<DeviceService>().addManualDevice(id: id.text.trim(), name: name.text.trim(), type: type, room: room.text.trim().isEmpty ? 'غير محدد' : room.text.trim()); Navigator.pop(dialogContext); }, child: const Text('إضافة'))],
      )));
    } finally { id.dispose(); name.dispose(); room.dispose(); }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeviceService>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.devices), actions: [IconButton(onPressed: _mqttDialog, icon: const Icon(Icons.hub_outlined, color: JavixColors.gold)), IconButton(onPressed: _manualDevice, icon: const Icon(Icons.add, color: JavixColors.gold))]),
      body: service.devices.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(28), child: GoldCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.devices_other, size: 54, color: JavixColors.gold), const SizedBox(height: 12), const Text('لا توجد أجهزة وهمية هنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 8), const Text('اربط MQTT أو أضف جهازاً حقيقياً من زر +. JARVIS لن يعرض أجهزة لم يتم تعريفها.', textAlign: TextAlign.center, style: TextStyle(color: JavixColors.textSecondary, height: 1.5)), const SizedBox(height: 16), FilledButton.icon(onPressed: _mqttDialog, icon: const Icon(Icons.hub, color: Colors.black), label: const Text('ربط MQTT', style: TextStyle(color: Colors.black)), style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(JavixColors.gold)))])))) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: service.devices.length, itemBuilder: (_, i) { final d = service.devices[i]; return Padding(padding: const EdgeInsets.only(bottom: 10), child: GoldCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(_icon(d.type), color: JavixColors.gold), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500)), Text(d.room, style: const TextStyle(color: JavixColors.textTertiary, fontSize: 12))])), Switch(value: d.isOn, onChanged: (_) => service.toggle(d))]), if (d.isOn) Slider(value: d.level.clamp(_min(d).round(), _max(d).round()).toDouble(), min: _min(d), max: _max(d), divisions: d.type == DeviceType.ac ? 14 : 20, label: _levelLabel(d), onChanged: (v) => service.setLevel(d, v.round(), publish: false), onChangeEnd: (v) => service.setLevel(d, v.round()))]))); }),
    );
  }
}
