import 'package:flutter/material.dart';
import '../../../widgets/gold_card.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/javix_theme.dart';
import '../../../data/services/ai_service.dart';

class DesignScreen extends StatefulWidget {
  const DesignScreen({super.key});

  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

class _DesignScreenState extends State<DesignScreen> {
  final _prompt = TextEditingController();
  String? _resultUrl;
  String? _rawResult;
  bool _busy = false;
  bool _video = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty) {
      _toast('اكتب وصف التصميم أولاً');
      return;
    }
    setState(() {
      _busy = true;
      _resultUrl = null;
      _rawResult = null;
    });
    try {
      final ai = context.read<AiService>();
      final result = _video ? await ai.generateVideo(prompt) : await ai.generateImage(prompt);
      if (!mounted) return;
      setState(() {
        if (result.startsWith('http')) {
          _resultUrl = result;
        } else {
          _rawResult = result;
        }
      });
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();
    return Scaffold(
      appBar: AppBar(title: const Text('JARVIS Design Studio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GoldCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: JavixColors.gold),
                SizedBox(width: 10),
                Expanded(child: Text('التصميم بالذكاء الاصطناعي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 8),
              const Text('اكتب فكرتك، وسيطلب JARVIS من بوابة الذكاء الاصطناعي إنشاء صورة أو فيديو مدته 10 ثوانٍ.', style: TextStyle(color: JavixColors.textSecondary, height: 1.5)),
              const SizedBox(height: 14),
              TextField(
                controller: _prompt,
                maxLines: 5,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'وصف التصميم',
                  hintText: 'مثال: شعار JARVIS فاخر، أسود وذهبي، شخص ملثم، إشارات تداول في الخلف...',
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.image_outlined), label: Text('صورة')),
                  ButtonSegment(value: true, icon: Icon(Icons.movie_outlined), label: Text('فيديو 10 ثوانٍ')),
                ],
                selected: {_video},
                onSelectionChanged: (s) => setState(() => _video = s.first),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy || !ai.configured ? null : _generate,
                  icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.auto_awesome, color: Colors.black),
                  label: Text(_busy ? 'جارِ الإنشاء...' : (_video ? 'إنشاء فيديو 10 ثوانٍ' : 'إنشاء التصميم'), style: const TextStyle(color: Colors.black)),
                  style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(14)),
                ),
              ),
              if (!ai.configured) ...[
                const SizedBox(height: 12),
                const Text('بوابة AI غير مهيأة. من لوحة المطور أضف رابط مزود الذكاء الاصطناعي قبل التوليد.', style: TextStyle(color: JavixColors.danger, fontSize: 12)),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          if (_resultUrl != null) _ResultCard(url: _resultUrl!, video: _video),
          if (_rawResult != null) GoldCard(child: SelectableText(_rawResult!, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String url;
  final bool video;
  const _ResultCard({required this.url, required this.video});

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(video ? 'الفيديو الناتج' : 'التصميم الناتج', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (!video)
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(20), child: Text('تعذر عرض الصورة هنا، استخدم الرابط أدناه.'))))
        else
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Icon(Icons.movie_creation_outlined, size: 56, color: JavixColors.gold))),
        const SizedBox(height: 10),
        SelectableText(url, style: const TextStyle(color: JavixColors.textSecondary, fontSize: 11)),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: url)), icon: const Icon(Icons.copy, color: JavixColors.gold)),
        ),
      ]),
    );
  }
}
