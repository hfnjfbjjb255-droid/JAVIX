import 'package:flutter/material.dart';

import '../../../core/theme/javix_theme.dart';

/// Developer-only: publish OTA updates to user devices.
class OtaManagerScreen extends StatefulWidget {
  const OtaManagerScreen({super.key});

  @override
  State<OtaManagerScreen> createState() => _OtaManagerScreenState();
}

class _OtaManagerScreenState extends State<OtaManagerScreen> {
  final _version = TextEditingController(text: '1.0.0');
  final _notes = TextEditingController();
  bool _rollout = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نشر التحديثات OTA')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _version, decoration: const InputDecoration(labelText: 'رقم الإصدار')),
        const SizedBox(height: 12),
        TextField(controller: _notes, maxLines: 4, decoration: const InputDecoration(labelText: 'ملاحظات الإصدار')),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _rollout,
          activeColor: JavixColors.gold,
          title: const Text('نشر تدريجي (10٪ أولاً)'),
          onChanged: (v) => setState(() => _rollout = v),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(14)),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('جاهز للنشر: ${_version.text} — اربطه بخادم OTA')),
          ),
          icon: const Icon(Icons.upload, color: Colors.black),
          label: const Text('نشر التحديث', style: TextStyle(color: Colors.black)),
        ),
      ]),
    );
  }
}
