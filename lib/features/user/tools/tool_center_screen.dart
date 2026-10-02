import '../../widgets/gold_card.dart';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/javix_theme.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/speech_service.dart';
import '../ai/ai_screen.dart';
import '../design/design_screen.dart';

/// Unified JARVIS tools hub inspired by modern AI assistants.
class ToolCenterScreen extends StatelessWidget {
  const ToolCenterScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _voice(BuildContext context) async {
    final speech = context.read<SpeechService>();
    if (speech.isListening) {
      await speech.stop();
      return;
    }
    await speech.listen((text) async {
      try {
        final reply = await context.read<AiService>().chat(text);
        await speech.speak(reply);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reply)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تشغيل الصوت: ${e.toString().replaceFirst('Exception: ', '')}')));
        }
      }
    });
  }

  Future<void> _file(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'json', 'csv', 'log'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;
    final file = result.files.single;
    String? content;
    try {
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
    } catch (_) {
      content = null;
    }
    if (content == null || content.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر قراءة الملف. جرّب ملف TXT أو MD أو JSON أو CSV.')));
      }
      return;
    }
    final clipped = content.length > 24000 ? content.substring(0, 24000) : content;
    _open(
      context,
      AiScreen(initialPrompt: 'حلّل الملف التالي باسم ${file.name}، لخّص محتواه، استخرج أهم النقاط والأخطاء إن وجدت، واقترح ما يمكن فعله به.\n\n$clipped'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tools = <_ToolItem>[
      _ToolItem(Icons.edit_note_outlined, 'كتابة', 'كتابة، تلخيص، إعادة صياغة', () => _open(context, const AiScreen())),
      _ToolItem(Icons.palette_outlined, 'صور', 'إنشاء أفكار وتصاميم', () => _open(context, const DesignScreen(initialVideo: false))),
      _ToolItem(Icons.movie_creation_outlined, 'فيديو', 'إنشاء فيديو قصير', () => _open(context, const DesignScreen(initialVideo: true))),
      _ToolItem(Icons.mic_none_outlined, 'صوت', 'تحدث مع JARVIS بصوتك', () => _voice(context)),
      _ToolItem(Icons.description_outlined, 'تحليل ملفات', 'TXT / MD / JSON / CSV', () => _file(context)),
      _ToolItem(Icons.search_outlined, 'بحث', 'حوّل طلبك إلى مهمة بحث', () => _open(context, const AiScreen(initialPrompt: 'أريد إجراء بحث منظم عن: '))),
      _ToolItem(Icons.code_outlined, 'برمجة', 'شرح، تصحيح وكتابة الكود', () => _open(context, const AiScreen(initialPrompt: 'أنت مساعد برمجة لـ JARVIS. حلّل أو اكتب أو صحح الكود التالي مع شرح مختصر:\n\n'))),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('مركز أدوات JARVIS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GoldCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Row(children: [
                Icon(Icons.auto_awesome, color: JavixColors.gold),
                SizedBox(width: 10),
                Text('مركز الأدوات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              ]),
              SizedBox(height: 8),
              Text('كل أدوات JARVIS في واجهة واحدة، مثل مراكز الأدوات الحديثة للمساعدات الذكية.', style: TextStyle(color: JavixColors.textSecondary, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.28),
            itemBuilder: (_, i) => _ToolCard(item: tools[i]),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _ToolItem(this.icon, this.title, this.subtitle, this.onTap);
}

class _ToolCard extends StatelessWidget {
  final _ToolItem item;
  const _ToolCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      onTap: item.onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: JavixColors.goldDim), color: JavixColors.gold.withValues(alpha: .07)), child: Icon(item.icon, color: JavixColors.gold)),
        const Spacer(),
        Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: JavixColors.textSecondary, fontSize: 11, height: 1.35)),
      ]),
    );
  }
}
