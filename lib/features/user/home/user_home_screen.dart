import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/localization/strings_ar.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/services/device_service.dart';
import '../../../data/services/search_service.dart';
import '../../../data/services/speech_service.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/voice_button.dart';
import '../camera/camera_search_screen.dart';
import '../devices/devices_screen.dart';
import '../reminders/reminders_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _tab = 0;

  Future<void> _toggleListening(SpeechService speech) async {
    if (speech.isListening) {
      await speech.stop();
    } else {
      await speech.listen((text) {
        final reply = context.read<DeviceService>().runVoiceCommand(text);
        context.read<SearchService>().log(text);
        speech.speak(reply);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reply)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _tab == 0 ? _buildHomeBody(speech) : _buildTabBody()),
            _buildBottomNav(speech),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: JavixColors.gold, width: 1.5),
            ),
            child: const Center(
              child: Text('J', style: TextStyle(color: JavixColors.gold, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JAVIX', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w500, fontSize: 17)),
              Text(AppConstants.appTagline, style: TextStyle(fontSize: 9, color: JavixColors.textTertiary, letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const GoldIcon(Icons.notifications_outlined), onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RemindersScreen()))),
          IconButton(
            icon: const GoldIcon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DevicesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const GoldIcon(Icons.logout),
            onPressed: () => context.read<PermissionService>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody(SpeechService speech) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Voice button centered, sized to the actual screen width so
          // it never forces the side cards into an overflow on 360dp phones.
          LayoutBuilder(
            builder: (_, constraints) {
              final size = (constraints.maxWidth * 0.52).clamp(140.0, 190.0);
              return VoiceButton(
                size: size,
                listening: speech.isListening,
                onTap: () => _toggleListening(speech),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(speech.isListening ? 'أستمع إليك...' : S.listening,
              style: const TextStyle(color: JavixColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 18),
          const Row(children: [
            Expanded(child: _InfoCard(icon: Icons.cloud_outlined, big: '28°', lines: ['البصرة', 'غائم جزئياً'])),
            SizedBox(width: 10),
            Expanded(child: _InfoCard(icon: Icons.calendar_month_outlined, big: 'الأربعاء', lines: ['2025 / 10 / 01'])),
            SizedBox(width: 10),
            Expanded(child: _InfoCard(icon: Icons.battery_3_bar_outlined, big: '78%', lines: ['البطارية'])),
          ]),
          const SizedBox(height: 18),
          // Five shortcuts: horizontal scroll instead of a cramped Row,
          // so nothing overflows on narrow screens.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _Shortcut(icon: Icons.camera_alt_outlined, label: S.cameraSearch, sub: S.cameraSearchSub,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CameraSearchScreen()))),
              _Shortcut(icon: Icons.public, label: S.webSearch, sub: S.webSearchSub, onTap: () {}),
              _Shortcut(icon: Icons.note_alt_outlined, label: S.notes, sub: S.notesSub, onTap: () {}),
              _Shortcut(icon: Icons.location_on_outlined, label: S.location, sub: S.locationSub, onTap: () {}),
              _Shortcut(icon: Icons.apps, label: S.apps, sub: S.appsSub, onTap: () {}),
            ]),
          ),
          const SizedBox(height: 16),
          const _HistoryPanel(),
          const SizedBox(height: 16),
          GoldCard(
            onTap: () {},
            child: Row(
              children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('معلومات سريعة', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('كل ما تحتاجه في مكان واحد', style: TextStyle(color: JavixColors.textSecondary, fontSize: 12)),
                    SizedBox(height: 10),
                    Text('استعرض المزيد ←', style: TextStyle(color: JavixColors.gold, fontSize: 13)),
                  ]),
                ),
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [JavixColors.gold.withValues(alpha: 0.5), Colors.transparent]),
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: JavixColors.gold, size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    return Center(
      child: Text([S.record, S.ai, S.profile][_tab - 1],
          style: const TextStyle(color: JavixColors.textSecondary)),
    );
  }

  Widget _buildBottomNav(SpeechService speech) {
    Widget item(IconData icon, String label, int i) {
      final active = _tab == i;
      return GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? JavixColors.gold : JavixColors.textTertiary, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: active ? JavixColors.gold : JavixColors.textTertiary)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: JavixColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          item(Icons.home_outlined, S.home, 0),
          item(Icons.schedule, S.record, 1),
          GestureDetector(
            onTap: () => _toggleListening(speech),
            child: Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: JavixColors.gold, width: 2),
              ),
              child: const Icon(Icons.mic, color: JavixColors.gold),
            ),
          ),
          item(Icons.psychology_outlined, S.ai, 2),
          item(Icons.person_outline, S.profile, 3),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String big;
  final List<String> lines;
  const _InfoCard({required this.icon, required this.big, required this.lines});

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GoldIcon(icon, size: 20),
        const SizedBox(height: 8),
        Text(big, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        ...lines.map((l) => Text(l, style: const TextStyle(color: JavixColors.textSecondary, fontSize: 11))),
      ]),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96, // fixed width so horizontal scroll lays out predictably
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: JavixColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JavixColors.border),
          ),
          child: Column(children: [
            GoldIcon(icon, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text(sub, style: const TextStyle(fontSize: 10, color: JavixColors.textTertiary)),
          ]),
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SearchService>().history;
    return GoldCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.graphic_eq, color: JavixColors.gold, size: 18),
          SizedBox(width: 8),
          Text(S.recentCommands, style: TextStyle(fontWeight: FontWeight.w500)),
          Spacer(),
          Icon(Icons.chevron_left, color: JavixColors.textTertiary),
        ]),
        const SizedBox(height: 10),
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('لا أوامر بعد — اضغط زر المايكروفون وابدأ', style: TextStyle(color: JavixColors.textTertiary, fontSize: 13)),
          )
        else
          ...history.take(5).map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Text('${e.at.hour}:${e.at.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: JavixColors.textTertiary, fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(e.kind == 'voice' ? Icons.search : Icons.location_on_outlined,
                      size: 16, color: JavixColors.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.command, style: const TextStyle(fontSize: 13))),
                ]),
              )),
      ]),
    );
  }
}
