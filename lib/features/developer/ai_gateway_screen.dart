import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/javix_theme.dart';
import '../../data/services/ai_service.dart';

class AiGatewayScreen extends StatefulWidget {
  const AiGatewayScreen({super.key});

  @override
  State<AiGatewayScreen> createState() => _AiGatewayScreenState();
}

class _AiGatewayScreenState extends State<AiGatewayScreen> {
  late final TextEditingController _base;
  late final TextEditingController _key;
  late final TextEditingController _image;
  late final TextEditingController _video;

  @override
  void initState() {
    super.initState();
    final ai = context.read<AiService>();
    _base = TextEditingController(text: ai.baseUrl);
    _key = TextEditingController();
    _image = TextEditingController(text: ai.imagePath);
    _video = TextEditingController(text: ai.videoPath);
  }

  @override
  void dispose() {
    _base.dispose(); _key.dispose(); _image.dispose(); _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('بوابة JARVIS AI')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      GoldCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('إعداد اتصال الذكاء الاصطناعي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text('استخدم خادمك/بوابتك الآمنة. لا تضع مفاتيح مزود الإنتاج داخل التطبيق إذا كانت قابلة للاستخراج؛ الأفضل خادم وسيط يحمي المفتاح.', style: TextStyle(color: JavixColors.textSecondary, height: 1.5)),
      ])),
      const SizedBox(height: 12),
      TextField(controller: _base, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://your-ai-gateway.example.com')),
      const SizedBox(height: 10),
      TextField(controller: _key, obscureText: true, decoration: const InputDecoration(labelText: 'API Key (اختياري)')),
      const SizedBox(height: 10),
      TextField(controller: _image, decoration: const InputDecoration(labelText: 'مسار توليد الصور')),
      const SizedBox(height: 10),
      TextField(controller: _video, decoration: const InputDecoration(labelText: 'مسار توليد الفيديو')),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: () async {
        await context.read<AiService>().saveConfig(baseUrl: _base.text, apiKey: _key.text, imagePath: _image.text, videoPath: _video.text);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات بوابة AI')));
      }, icon: const Icon(Icons.save, color: Colors.black), label: const Text('حفظ', style: TextStyle(color: Colors.black)), style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(14))),
    ],
  );
}
