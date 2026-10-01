import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/services/device_service.dart';
import '../../../data/services/device_status_service.dart';
import '../../../data/services/search_service.dart';
import '../../../data/services/speech_service.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/voice_button.dart';
import '../ai/ai_screen.dart';
import '../camera/camera_search_screen.dart';
import '../design/design_screen.dart';
import '../devices/devices_screen.dart';
import '../reminders/reminders_screen.dart';
import '../system/permissions_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _tab = 0;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DeviceStatusService>().start());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening(SpeechService speech) async {
    if (speech.isListening) {
      await speech.stop();
      return;
    }
    await speech.listen((text) {
      final reply = context.read<DeviceService>().runVoiceCommand(text);
      context.read<SearchService>().log(text);
      speech.speak(reply);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reply)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    return Scaffold(
      body: SafeArea(child: Column(children: [
        _header(),
        Expanded(child: IndexedStack(index: _tab, children: [
          _home(speech),
          const AiScreen(),
          const DesignScreen(),
          const _ProfileTab(),
        ])),
        _bottomNav(speech),
      ])),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: JavixColors.gold, width: 1.5), gradient: const RadialGradient(colors: [JavixColors.surfaceLight, JavixColors.background])), child: const Center(child: Text('J', style: TextStyle(color: JavixColors.gold, fontWeight: FontWeight.w700, fontSize: 21)))),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JARVIS', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w600, fontSize: 17)), Text(AppConstants.appTagline, style: TextStyle(fontSize: 8, color: JavixColors.textTertiary, letterSpacing: 1.5))]),
      const Spacer(),
      IconButton(icon: const Icon(Icons.notifications_none, color: JavixColors.gold), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()))),
      IconButton(icon: const Icon(Icons.logout, color: JavixColors.textSecondary), onPressed: () => context.read<PermissionService>().logout()),
    ]),
  );

  Widget _home(SpeechService speech) {
    final status = context.watch<DeviceStatusService>();
    final date = DateFormat('yyyy / MM / dd', 'ar').format(_now);
    final day = DateFormat('EEEE', 'ar').format(_now);
    return RefreshIndicator(
      color: JavixColors.gold,
      onRefresh: status.refresh,
      child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        const SizedBox(height: 8),
        LayoutBuilder(builder: (_, c) => VoiceButton(size: (c.maxWidth * .48).clamp(145.0, 185.0), listening: speech.isListening, onTap: () => _toggleListening(speech))),
        const SizedBox(height: 8),
        Center(child: Text(speech.isListening ? 'أستمع إليك الآن...' : 'جاهز لأمرك', style: const TextStyle(color: JavixColors.textSecondary))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _InfoCard(icon: Icons.cloud_outlined, big: status.temperature == null ? '--' : '${status.temperature!.round()}°', lines: [status.place, status.weatherText])),
          const SizedBox(width: 8),
          Expanded(child: _InfoCard(icon: Icons.calendar_month_outlined, big: day, lines: [date, DateFormat('HH:mm:ss').format(_now)])),
          const SizedBox(width: 8),
          Expanded(child: _InfoCard(icon: Icons.battery_std, big: status.battery == null ? '--' : '${status.battery}%', lines: ['بطارية الجهاز', status.battery == null ? 'جارِ القراءة' : 'حقيقية من النظام'])),
        ]),
        const SizedBox(height: 16),
        const Text('مركز JARVIS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.65, mainAxisSpacing: 10, crossAxisSpacing: 10, children: [
          _ActionCard(icon: Icons.auto_awesome, title: 'Design Studio', sub: 'صور + فيديو 10 ثوانٍ', onTap: () => setState(() => _tab = 2)),
          _ActionCard(icon: Icons.psychology_outlined, title: 'JARVIS AI', sub: 'أوامر ومحادثة', onTap: () => setState(() => _tab = 1)),
          _ActionCard(icon: Icons.camera_alt_outlined, title: 'الرؤية', sub: 'كاميرا وتحليل', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraSearchScreen()))),
          _ActionCard(icon: Icons.home_work_outlined, title: 'الأجهزة', sub: 'تحكم محلي / MQTT', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesScreen()))),
          _ActionCard(icon: Icons.notifications_active_outlined, title: 'التذكيرات', sub: 'مواعيد وتنبيهات', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()))),
          _ActionCard(icon: Icons.security_outlined, title: 'الأذونات', sub: 'ميكروفون، كاميرا، Bluetooth...', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()))),
        ]),
        const SizedBox(height: 16),
        const _HistoryPanel(),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _bottomNav(SpeechService speech) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: JavixColors.border))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _NavItem(icon: Icons.home_outlined, label: 'الرئيسية', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
      _NavItem(icon: Icons.psychology_outlined, label: 'AI', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
      GestureDetector(onTap: () => _toggleListening(speech), child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: JavixColors.gold, width: 2), boxShadow: [BoxShadow(color: JavixColors.gold.withValues(alpha: .15), blurRadius: 18)]), child: Icon(speech.isListening ? Icons.stop : Icons.mic, color: JavixColors.gold))),
      _NavItem(icon: Icons.auto_awesome, label: 'Design', active: _tab == 2, onTap: () => setState(() => _tab = 2)),
      _NavItem(icon: Icons.person_outline, label: 'حسابي', active: _tab == 3, onTap: () => setState(() => _tab = 3)),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String big; final List<String> lines;
  const _InfoCard({required this.icon, required this.big, required this.lines});
  @override Widget build(BuildContext context) => GoldCard(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: JavixColors.gold, size: 20), const SizedBox(height: 6), Text(big, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)), ...lines.map((x) => Text(x, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: JavixColors.textSecondary, fontSize: 9)))]));
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title; final String sub; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.sub, required this.onTap});
  @override Widget build(BuildContext context) => GoldCard(onTap: onTap, padding: const EdgeInsets.all(12), child: Row(children: [Icon(icon, color: JavixColors.gold, size: 27), const SizedBox(width: 10), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: JavixColors.textTertiary, fontSize: 10))]))]));
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? JavixColors.gold : JavixColors.textTertiary, size: 23), Text(label, style: TextStyle(fontSize: 9, color: active ? JavixColors.gold : JavixColors.textTertiary))]));
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel();
  @override Widget build(BuildContext context) {
    final history = context.watch<SearchService>().history;
    return GoldCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.graphic_eq, color: JavixColors.gold, size: 18), SizedBox(width: 8), Text('آخر الأوامر', style: TextStyle(fontWeight: FontWeight.w600))]),
      const SizedBox(height: 8),
      if (history.isEmpty) const Text('لا توجد أوامر بعد. اضغط الميكروفون وابدأ.', style: TextStyle(color: JavixColors.textTertiary, fontSize: 12)) else ...history.take(5).map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Text('${e.at.hour}:${e.at.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: JavixColors.textTertiary, fontSize: 11)), const SizedBox(width: 10), Expanded(child: Text(e.command, maxLines: 1, overflow: TextOverflow.ellipsis))]))),
    ]));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override Widget build(BuildContext context) {
    final auth = context.watch<PermissionService>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      GoldCard(child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: JavixColors.gold)), child: const Center(child: Text('J', style: TextStyle(color: JavixColors.gold, fontSize: 24, fontWeight: FontWeight.bold)))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(auth.userId ?? 'مستخدم', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)), const Text('JARVIS User Edition', style: TextStyle(color: JavixColors.textSecondary))]))])),
      const SizedBox(height: 12),
      ListTile(leading: const Icon(Icons.security_outlined, color: JavixColors.gold), title: const Text('الأذونات'), subtitle: const Text('إدارة أذونات Android'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()))),
      ListTile(leading: const Icon(Icons.devices_other, color: JavixColors.gold), title: const Text('الأجهزة المنزلية'), subtitle: const Text('الأجهزة المحلية وMQTT'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesScreen()))),
      ListTile(leading: const Icon(Icons.logout, color: JavixColors.textSecondary), title: const Text('تسجيل الخروج'), onTap: auth.logout),
    ]);
  }
}
