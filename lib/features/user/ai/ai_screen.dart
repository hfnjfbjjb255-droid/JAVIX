import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/javix_theme.dart';
import '../../../data/services/ai_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _prompt = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GoldCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.psychology_outlined, color: JavixColors.gold), SizedBox(width: 10), Text('JARVIS AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 8),
          Text(ai.configured ? 'متصل ببوابة الذكاء الاصطناعي' : 'غير متصل ببوابة AI بعد', style: TextStyle(color: ai.configured ? JavixColors.success : JavixColors.textSecondary)),
        ])),
        const SizedBox(height: 16),
        ..._messages.map((m) => Align(alignment: Alignment.centerRight, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: JavixColors.surfaceLight, borderRadius: BorderRadius.circular(12)), child: Text(m)))),
        GoldCard(child: Column(children: [
          TextField(controller: _prompt, maxLines: 4, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'اكتب أمرك لـ JARVIS...')),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: () {
            final text = _prompt.text.trim();
            if (text.isEmpty) return;
            setState(() { _messages.insert(0, 'أنت: $text'); _prompt.clear(); });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ai.configured ? 'الأمر جاهز للإرسال إلى بوابة AI.' : 'فعّل بوابة AI من لوحة المطور أولاً.')));
          }, icon: const Icon(Icons.send, color: Colors.black), label: const Text('إرسال', style: TextStyle(color: Colors.black)), style: FilledButton.styleFrom(backgroundColor: JavixColors.gold)))
        ])),
      ],
    );
  }
}
