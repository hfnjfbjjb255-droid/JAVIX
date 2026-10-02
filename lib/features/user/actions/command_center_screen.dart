import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/device_service.dart';
import '../../../data/services/search_service.dart';
import '../../../data/services/speech_service.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/jarvis_ambient_background.dart';
import '../../../widgets/jarvis_core.dart';
import '../ai/ai_screen.dart';
import '../devices/devices_screen.dart';
import '../reminders/reminders_screen.dart';
import '../tools/tool_center_screen.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});
  @override State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  JarvisCoreState _state = JarvisCoreState.standby;
  String _activity = 'مركز الأوامر جاهز';

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() { _state = JarvisCoreState.working; _activity = 'جارٍ تنفيذ: $label'; });
    try {
      await action();
      if (!mounted) return;
      setState(() { _state = JarvisCoreState.completed; _activity = 'اكتملت: $label'; });
      Future<void>.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _state = JarvisCoreState.standby); });
    } catch (e) {
      if (!mounted) return;
      setState(() { _state = JarvisCoreState.error; _activity = 'تعذر تنفيذ: $label'; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override Widget build(BuildContext context) {
    final history = context.watch<SearchService>().history;
    final ai = context.watch<AiService>();
    final devices = context.watch<DeviceService>();
    return Scaffold(
      appBar: AppBar(title: const Text('JARVIS Command Center'), backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        Positioned.fill(child: JarvisAmbientBackground(state: _state)),
        SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 72, 16, 28), children: [
          Center(child: JarvisCore(size: 154, state: _state, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen())))),
          const SizedBox(height: 8),
          Center(child: Text(_activity, textAlign: TextAlign.center, style: const TextStyle(color: JavixColors.textSecondary, fontSize: 12))),
          const SizedBox(height: 18),
          _statusStrip(ai.configured, devices.useMqtt),
          const SizedBox(height: 14),
          const Text('إجراءات JARVIS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.25, children: [
            _Action(icon: Icons.psychology_outlined, title: 'محادثة AI', subtitle: ai.configured ? 'جاهز للتنفيذ' : 'اضبط بوابة AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen()))),
            _Action(icon: Icons.notifications_active_outlined, title: 'التذكيرات', subtitle: 'أنشئ أو راجع مهامك', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()))),
            _Action(icon: Icons.home_work_outlined, title: 'الأجهزة', subtitle: devices.useMqtt ? 'MQTT متاح' : 'تحكم محلي', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesScreen()))),
            _Action(icon: Icons.apps_outlined, title: 'مركز الأدوات', subtitle: '7 أدوات في مكان واحد', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolCenterScreen()))),
            _Action(icon: Icons.volume_up_outlined, title: 'اختبار الصوت', subtitle: 'JARVIS يتكلم', onTap: () => _run('اختبار الصوت', () async { await context.read<SpeechService>().speak('مرحباً، أنا JARVIS. النظام يعمل بشكل طبيعي.'); })),
            _Action(icon: Icons.cleaning_services_outlined, title: 'تنظيف النشاط', subtitle: 'يمسح سجل الأوامر المحلي', onTap: () => _run('تنظيف النشاط', () async { context.read<SearchService>().clear(); })),
          ]),
          const SizedBox(height: 18),
          GoldCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.timeline, color: JavixColors.gold, size: 19), SizedBox(width: 8), Text('سجل النشاط', style: TextStyle(fontWeight: FontWeight.w700))]),
            const SizedBox(height: 10),
            if (history.isEmpty) const Text('لا توجد عمليات بعد. عندما ينفذ JARVIS أمراً ستظهر هنا حالته ووقته.', style: TextStyle(color: JavixColors.textTertiary, fontSize: 11))
            else ...history.take(8).map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Text('${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: JavixColors.textTertiary, fontSize: 10)), const SizedBox(width: 10), Expanded(child: Text(e.command, maxLines: 1, overflow: TextOverflow.ellipsis)), Text(e.kind, style: const TextStyle(color: JavixColors.textTertiary, fontSize: 9))]))),
          ])),
          const SizedBox(height: 12),
          Text('النواة تتغير حسب المهمة: Listening → Thinking → Working → Completed / Error', textAlign: TextAlign.center, style: TextStyle(color: JavixColors.textTertiary.withValues(alpha: .85), fontSize: 10)),
        ])),
      ]),
    );
  }

  Widget _statusStrip(bool ai, bool mqtt) => ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10), decoration: BoxDecoration(color: JavixColors.surface.withValues(alpha: .72), borderRadius: BorderRadius.circular(18), border: Border.all(color: JavixColors.border)), child: Row(children: [const Icon(Icons.bolt, color: JavixColors.gold, size: 18), const SizedBox(width: 7), const Expanded(child: Text('جاهزية النظام', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))), _dot('AI', ai), _dot('MQTT', mqtt), _dot('CORE', true)]))));
  Widget _dot(String label, bool active) => Padding(padding: const EdgeInsets.only(left: 10), child: Row(children: [Icon(Icons.circle, size: 6, color: active ? JavixColors.success : JavixColors.textTertiary), const SizedBox(width: 3), Text(label, style: const TextStyle(fontSize: 7, color: JavixColors.textTertiary))]));
}

class _Action extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _Action({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override Widget build(BuildContext context) => GoldCard(onTap: onTap, padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: JavixColors.gold.withValues(alpha: .08), border: Border.all(color: JavixColors.gold.withValues(alpha: .25))), child: Icon(icon, color: JavixColors.gold, size: 20)), const SizedBox(height: 9), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: JavixColors.textTertiary, fontSize: 9))]));
}
