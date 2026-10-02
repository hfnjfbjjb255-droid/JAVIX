import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/localization/language_service.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/services/device_service.dart';
import '../../../data/services/device_status_service.dart';
import '../../../data/services/search_service.dart';
import '../../../data/services/speech_service.dart';
import '../../../data/services/ai_service.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/jarvis_core.dart';
import '../../../widgets/jarvis_ambient_background.dart';
import '../../../widgets/animated_jarvis_text.dart';
import '../ai/ai_screen.dart';
import '../actions/command_center_screen.dart';
import '../camera/camera_search_screen.dart';
import '../design/design_screen.dart';
import '../devices/devices_screen.dart';
import '../reminders/reminders_screen.dart';
import '../system/permissions_screen.dart';
import '../subscription/subscription_screen.dart';
import '../tools/tool_center_screen.dart';
import '../translation/translation_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _tab = 0;
  Timer? _clock;
  DateTime _now = DateTime.now();
  JarvisCoreState _coreState = JarvisCoreState.standby;
  Timer? _coreResetTimer;
  bool _backendOnline = false;
  String _activity = 'النظام في وضع الاستعداد';
  DateTime _activityAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceStatusService>().start();
      // Local mode intentionally does not poll a backend.
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _coreResetTimer?.cancel();
    super.dispose();
  }

  void _setCoreState(JarvisCoreState state, {Duration resetAfter = const Duration(seconds: 3)}) {
    _coreResetTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _coreState = state;
      _activityAt = DateTime.now();
      _activity = _activityLabel(state);
    });
    if (state == JarvisCoreState.completed || state == JarvisCoreState.error) {
      _coreResetTimer = Timer(resetAfter, () {
        if (mounted) setState(() => _coreState = JarvisCoreState.standby);
      });
    }
  }

  Future<void> _toggleListening(SpeechService speech) async {
    if (speech.isListening) {
      await speech.stop();
      _setCoreState(JarvisCoreState.standby);
      return;
    }
    _setCoreState(JarvisCoreState.listening);
    await speech.listen((text) async {
      context.read<SearchService>().log(text);
      _setCoreState(JarvisCoreState.thinking);
      String reply;
      final deviceService = context.read<DeviceService>();
      final deviceReply = deviceService.runVoiceCommand(text);
      final handledByDevice = deviceReply.startsWith('تم تشغيل') || deviceReply.startsWith('تم إطفاء');
      if (handledByDevice) {
        _setCoreState(JarvisCoreState.working);
        reply = deviceReply;
      } else {
        final ai = context.read<AiService>();
        if (ai.configured) {
          try {
            reply = await ai.chat(text);
          } catch (e) {
            _setCoreState(JarvisCoreState.error);
            reply = 'تعذر الوصول إلى JARVIS AI حالياً: ${e.toString().replaceFirst('Exception: ', '')}';
            await speech.speak(reply);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reply)));
            return;
          }
        } else {
          reply = deviceReply;
        }
      }
      _setCoreState(JarvisCoreState.completed);
      await speech.speak(reply);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reply)));
    });
  }

  String _activityLabel(JarvisCoreState state) {
    switch (state) {
      case JarvisCoreState.listening: return 'JARVIS يستمع للأمر الصوتي';
      case JarvisCoreState.thinking: return 'JARVIS يحلل الطلب';
      case JarvisCoreState.working: return 'JARVIS ينفذ المهمة';
      case JarvisCoreState.completed: return 'اكتملت المهمة بنجاح';
      case JarvisCoreState.error: return 'حدث خطأ في تنفيذ المهمة';
      case JarvisCoreState.standby: return 'النظام في وضع الاستعداد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    return Scaffold(
      body: SafeArea(child: Column(children: [
        _header(),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          reverseDuration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(children: [
            ...previous,
            if (current != null) current,
          ]),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: IndexedStack(
            key: ValueKey(_tab),
            index: _tab,
            children: [
              _home(speech),
              const AiScreen(),
              const DesignScreen(),
              const _ProfileTab(),
            ],
          ),
        )),
        _bottomNav(speech),
      ])),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: JavixColors.gold, width: 1.5),
            gradient: const RadialGradient(
              colors: [JavixColors.surfaceLight, JavixColors.background],
            ),
          ),
          child: const Center(
            child: Text(
              'J',
              style: TextStyle(
                color: JavixColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 21,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedJarvisText(
                fontSize: 17,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
                compact: true,
              ),
              Text(
                AppConstants.appTagline,
                style: TextStyle(
                  fontSize: 8,
                  color: JavixColors.textTertiary,
                  letterSpacing: 1.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'الترجمة',
          icon: const Icon(Icons.translate, color: JavixColors.gold),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TranslationScreen(),
            ),
          ),
        ),
        IconButton(
          tooltip: 'اللغات',
          icon: const Icon(Icons.language, color: JavixColors.gold),
          onPressed: () => _showLanguagePicker(context),
        ),
        IconButton(
          tooltip: 'التذكيرات',
          icon: const Icon(
            Icons.notifications_none,
            color: JavixColors.gold,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RemindersScreen(),
            ),
          ),
        ),
        IconButton(
          tooltip: 'تسجيل الخروج',
          icon: const Icon(
            Icons.logout,
            color: JavixColors.textSecondary,
          ),
          onPressed: () => context.read<PermissionService>().logout(),
        ),
      ],
    ),
  );

  Future<void> _showLanguagePicker(BuildContext context) async {
    final service = context.read<LanguageService>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: JavixColors.surface,
      showDragHandle: true,
      builder: (_) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'لغات JARVIS',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...LanguageService.languages.map(
            (language) => ListTile(
              leading: Icon(
                language.code == service.locale.languageCode
                    ? Icons.check_circle
                    : Icons.language,
                color: language.code == service.locale.languageCode
                    ? JavixColors.gold
                    : JavixColors.textTertiary,
              ),
              title: Text(language.nativeName),
              subtitle: Text(language.name),
              onTap: () => Navigator.pop(context, language.code),
            ),
          ),
        ],
      ),
    );

    if (selected != null) {
      await service.setLanguage(selected);
    }
  }

  Widget _home(SpeechService speech) {
    final status = context.watch<DeviceStatusService>();
    final date = DateFormat('yyyy / MM / dd', 'ar').format(_now);
    final day = DateFormat('EEEE', 'ar').format(_now);
    return Stack(
      children: [
        Positioned.fill(child: JarvisAmbientBackground(state: speech.isListening ? JarvisCoreState.listening : _coreState)),
        RefreshIndicator(
          color: JavixColors.gold,
          onRefresh: status.refresh,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 72, 16, 16), children: [
        const SizedBox(height: 8),
        LayoutBuilder(builder: (_, c) => JarvisCore(
          size: (c.maxWidth * .48).clamp(165.0, 205.0),
          state: speech.isListening ? JarvisCoreState.listening : _coreState,
          onTap: () => _toggleListening(speech),
        )),
        const SizedBox(height: 2),
        Center(child: Text(_coreState == JarvisCoreState.standby && !speech.isListening ? 'اضغط على النواة وتحدث مع JARVIS' : _coreStatusHint(), style: const TextStyle(color: JavixColors.textSecondary, fontSize: 12))),
        const SizedBox(height: 10),
        _quickCommandRow(),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () async {
              await status.refresh();
              if (mounted && status.location == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(status.locationMessage)),
                );
              }
            }, child: _InfoCard(icon: Icons.cloud_outlined, big: status.temperature == null ? '--' : '${status.temperature!.round()}°', lines: [status.place, status.weatherText]))),
          const SizedBox(width: 8),
          Expanded(child: _InfoCard(icon: Icons.calendar_month_outlined, big: day, lines: [date, DateFormat('HH:mm:ss').format(_now)])),
          const SizedBox(width: 8),
          Expanded(child: _InfoCard(icon: Icons.battery_std, big: status.battery == null ? '--' : '${status.battery}%', lines: ['بطارية الجهاز', status.battery == null ? 'جارِ القراءة' : 'حقيقية من النظام'])),
        ]),
        const SizedBox(height: 16),
        const Text('مركز JARVIS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.65, mainAxisSpacing: 10, crossAxisSpacing: 10, children: [
          _ActionCard(icon: Icons.bolt, title: 'مركز الأوامر', sub: 'تنفيذ • نشاط • حالة JARVIS', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandCenterScreen()))),
          _ActionCard(icon: Icons.apps_outlined, title: 'مركز الأدوات', sub: 'كتابة • صور • فيديو • صوت • ملفات • بحث • برمجة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolCenterScreen()))),
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
    ),
        _liveStatus(status),
      ],
    );
  }

  Widget _liveStatus(DeviceStatusService status) {
    final ai = context.watch<AiService>();
    final devices = context.watch<DeviceService>();
    return Positioned(
      top: 10,
      left: 18,
      right: 18,
      child: _LiveConnectionBar(
        aiOnline: ai.configured,
        backendOnline: _backendOnline,
        mqttOnline: devices.useMqtt,
        locationOnline: status.location != null,
        activity: _activity,
        activityAt: _activityAt,
      ),
    );
  }

  String _coreStatusHint() {
    switch (_coreState) {
      case JarvisCoreState.listening: return 'أستمع إليك الآن...';
      case JarvisCoreState.thinking: return 'أحلل طلبك وأجهز الإجابة...';
      case JarvisCoreState.working: return 'أنفذ المهمة الآن...';
      case JarvisCoreState.completed: return 'اكتملت المهمة بنجاح ✓';
      case JarvisCoreState.error: return 'حدث خطأ، حاول مرة أخرى';
      case JarvisCoreState.standby: return 'جاهز لأمرك';
    }
  }

  Widget _quickCommandRow() => SizedBox(
    height: 38,
    child: ListView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      children: [
        _QuickChip(label: 'اسأل JARVIS', icon: Icons.psychology_outlined, onTap: () => setState(() => _tab = 1)),
        _QuickChip(label: 'مركز الأدوات', icon: Icons.apps_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolCenterScreen()))),
        _QuickChip(label: 'الرؤية', icon: Icons.visibility_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraSearchScreen()))),
        _QuickChip(label: 'الأجهزة', icon: Icons.home_work_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesScreen()))),
      ],
    ),
  );

  Widget _bottomNav(SpeechService speech) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: JavixColors.surface.withValues(alpha: .78),
          border: const Border(top: BorderSide(color: JavixColors.border)),
          boxShadow: [BoxShadow(color: JavixColors.gold.withValues(alpha: .05), blurRadius: 24, offset: const Offset(0, -6))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _NavItem(icon: Icons.home_outlined, label: 'الرئيسية', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
          _NavItem(icon: Icons.psychology_outlined, label: 'AI', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
          GestureDetector(onTap: () => _toggleListening(speech), child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: JavixColors.gold, width: 2), boxShadow: [BoxShadow(color: JavixColors.gold.withValues(alpha: .15), blurRadius: 18)]), child: Icon(speech.isListening ? Icons.stop : Icons.mic, color: JavixColors.gold))),
          _NavItem(icon: Icons.auto_awesome, label: 'Design', active: _tab == 2, onTap: () => setState(() => _tab = 2)),
          _NavItem(icon: Icons.person_outline, label: 'حسابي', active: _tab == 3, onTap: () => setState(() => _tab = 3)),
        ]),
      ),
    ),
  );
}


class _LiveConnectionBar extends StatelessWidget {
  final bool aiOnline;
  final bool backendOnline;
  final bool mqttOnline;
  final bool locationOnline;
  final String activity;
  final DateTime activityAt;

  const _LiveConnectionBar({
    required this.aiOnline,
    required this.backendOnline,
    required this.mqttOnline,
    required this.locationOnline,
    required this.activity,
    required this.activityAt,
  });

  @override
  Widget build(BuildContext context) {
    final online = aiOnline || backendOnline;
    final color = online ? JavixColors.success : JavixColors.gold;
    final time = '${activityAt.hour.toString().padLeft(2, '0')}:${activityAt.minute.toString().padLeft(2, '0')}';
    return Material(
      color: Colors.transparent,
      child: GoldCard(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: .55), blurRadius: 9)]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('آخر نشاط $time', style: const TextStyle(fontSize: 8, color: JavixColors.textTertiary)),
                ],
              ),
            ),
            _StatusDot(label: 'AI', active: aiOnline),
            _StatusDot(label: 'SYS', active: backendOnline),
            _StatusDot(label: 'MQTT', active: mqttOnline),
            _StatusDot(label: 'GPS', active: locationOnline),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final bool active;
  const _StatusDot({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Column(
      children: [
        Icon(Icons.circle, size: 6, color: active ? JavixColors.success : JavixColors.textTertiary),
        Text(label, style: const TextStyle(fontSize: 6, color: JavixColors.textTertiary)),
      ],
    ),
  );
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 7),
    child: ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: JavixColors.gold),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      side: const BorderSide(color: JavixColors.border),
      backgroundColor: JavixColors.surface,
    ),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<PermissionService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GoldCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: JavixColors.gold),
                ),
                child: const Center(
                  child: Text(
                    'J',
                    style: TextStyle(
                      color: JavixColors.gold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.userId ?? 'مستخدم',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'JARVIS User Edition',
                      style: TextStyle(
                        color: JavixColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(
            Icons.language,
            color: JavixColors.gold,
          ),
          title: const Text('اللغات'),
          subtitle: const Text('اختر لغة واجهة JARVIS'),
          onTap: () async {
            final service = context.read<LanguageService>();
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: JavixColors.surface,
              showDragHandle: true,
              builder: (_) => ListView(
                children: LanguageService.languages
                    .map(
                      (language) => ListTile(
                        leading: Icon(
                          language.code == service.locale.languageCode
                              ? Icons.check_circle
                              : Icons.language,
                          color: language.code == service.locale.languageCode
                              ? JavixColors.gold
                              : JavixColors.textTertiary,
                        ),
                        title: Text(language.nativeName),
                        subtitle: Text(language.name),
                        onTap: () =>
                            Navigator.pop(context, language.code),
                      ),
                    )
                    .toList(),
              ),
            );
            if (selected != null) {
              await service.setLanguage(selected);
            }
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.translate,
            color: JavixColors.gold,
          ),
          title: const Text('الترجمة'),
          subtitle: const Text('ترجمة النصوص إلى لغات متعددة'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TranslationScreen(),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(
            Icons.security_outlined,
            color: JavixColors.gold,
          ),
          title: const Text('الأذونات'),
          subtitle: const Text('إدارة أذونات Android'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PermissionsScreen(),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(
            Icons.devices_other,
            color: JavixColors.gold,
          ),
          title: const Text('الأجهزة المنزلية'),
          subtitle: const Text('الأجهزة المحلية وMQTT'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DevicesScreen(),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(
            Icons.workspace_premium_outlined,
            color: JavixColors.gold,
          ),
          title: const Text('اشتراك JARVIS Pro'),
          subtitle: const Text('شهري / 3 أشهر / سنوي'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SubscriptionScreen(),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(
            Icons.logout,
            color: JavixColors.textSecondary,
          ),
          title: const Text('تسجيل الخروج'),
          onTap: auth.logout,
        ),
      ],
    );
  }
}
