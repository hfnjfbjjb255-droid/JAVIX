import 'package:flutter/material.dart';
import '../../../widgets/gold_card.dart';

import '../../../core/platform/jarvis_platform.dart';
import '../../../core/theme/javix_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<String, bool> _status = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final status = await JarvisPlatform.permissionStatus();
    if (mounted) setState(() { _status = status; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final labels = <String, String>{
      'microphone': 'الميكروفون',
      'camera': 'الكاميرا',
      'location': 'الموقع',
      'photos': 'الصور',
      'videos': 'الفيديوهات',
      'audioFiles': 'ملفات الصوت',
      'storage': 'الملفات والتخزين',
      'notifications': 'الإشعارات',
      'bluetooth': 'Bluetooth',
      'bluetoothScan': 'اكتشاف Bluetooth',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('أذونات JARVIS')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GoldCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('تحكم كامل وواضح', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('JARVIS يطلب فقط الأذونات التي يدعمها النظام فعلياً. الموافقة النهائية تبقى بيد Android.', style: TextStyle(color: JavixColors.textSecondary, height: 1.5)),
        ])),
        const SizedBox(height: 12),
        if (_loading) const Center(child: CircularProgressIndicator(color: JavixColors.gold)) else ...labels.entries.map((entry) {
          final granted = _status[entry.key] == true;
          return Card(child: ListTile(leading: Icon(granted ? Icons.check_circle : Icons.cancel_outlined, color: granted ? JavixColors.success : JavixColors.danger), title: Text(entry.value), subtitle: Text(granted ? 'مسموح' : 'غير مسموح')));
        }),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: () async { await JarvisPlatform.requestAllRelevantPermissions(); await Future<void>.delayed(const Duration(milliseconds: 400)); await _refresh(); }, icon: const Icon(Icons.security, color: Colors.black), label: const Text('طلب الأذونات مرة أخرى', style: TextStyle(color: Colors.black)), style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(14))),
      ]),
    );
  }
}
