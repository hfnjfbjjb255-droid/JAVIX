import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/javix_theme.dart';
import '../../../data/services/ai_service.dart';
import '../../../widgets/animated_jarvis_text.dart';
import '../../../widgets/gold_card.dart';

class AiScreen extends StatefulWidget {
  final String? initialPrompt;
  const AiScreen({super.key, this.initialPrompt});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _prompt = TextEditingController();
  final List<({bool user, String text})> _messages = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) _prompt.text = widget.initialPrompt!;
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _prompt.text.trim();
    if (text.isEmpty || _busy) return;
    final ai = context.read<AiService>();
    setState(() {
      _messages.add((user: true, text: text));
      _prompt.clear();
      _busy = true;
    });
    try {
      final reply = await ai.chat(text);
      if (!mounted) return;
      setState(() => _messages.add((user: false, text: reply)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add((user: false, text: e.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GoldCard(child: Row(children: [
          const Icon(Icons.psychology_outlined, color: JavixColors.gold),
          const SizedBox(width: 10),
          const AnimatedJarvisText(fontSize: 18, letterSpacing: 3, compact: true),
          const Spacer(),
          Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: ai.configured ? JavixColors.success : JavixColors.danger)),
        ])),
        const SizedBox(height: 10),
        Text(ai.serverMode ? 'متصل بخادم JARVIS الآمن' : (ai.configured ? 'متصل ببوابة AI المحلية' : 'خادم JARVIS غير مهيأ بعد'), style: TextStyle(color: ai.configured ? JavixColors.success : JavixColors.textSecondary)),
        const SizedBox(height: 14),
        if (_messages.isEmpty)
          const GoldCard(child: Text('اكتب أي سؤال أو أمر. JARVIS سيرسل النص إلى بوابة الذكاء الاصطناعي ويرجع لك الجواب الحقيقي.', style: TextStyle(color: JavixColors.textSecondary, height: 1.6)))
        else
          ..._messages.map((m) => Align(
            alignment: m.user ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: m.user ? JavixColors.surfaceLight : const Color(0x1FD4A24E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: m.user ? JavixColors.border : JavixColors.goldDim),
              ),
              child: Text(m.text, textAlign: TextAlign.right, style: const TextStyle(height: 1.5)),
            ),
          )),
        if (_busy) const Padding(padding: EdgeInsets.all(8), child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: JavixColors.gold)), SizedBox(width: 10), Text('JARVIS يفكر...')])) ,
        const SizedBox(height: 8),
        GoldCard(child: Column(children: [
          TextField(controller: _prompt, maxLines: 4, textAlign: TextAlign.right, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'اكتب أمرك لـ JARVIS...')),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy || !ai.configured ? null : _send, icon: const Icon(Icons.send, color: Colors.black), label: const Text('إرسال إلى JARVIS', style: TextStyle(color: Colors.black)), style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(14)))),
        ])),
      ],
    );
  }
}
