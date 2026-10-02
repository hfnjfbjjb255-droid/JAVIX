import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/permissions/permission_service.dart';
import '../../core/theme/javix_theme.dart';
import '../../data/services/backend_service.dart';
import '../../widgets/animated_jarvis_logo.dart';
import '../../widgets/gold_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _devCode = TextEditingController();
  final _localAuth = LocalAuthentication();
  int _mode = 0; // 0 email, 1 phone, 2 developer
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  bool _otpSent = false;

  @override
  void dispose() { _email.dispose(); _password.dispose(); _name.dispose(); _phone.dispose(); _otp.dispose(); _devCode.dispose(); super.dispose(); }

  Future<void> _emailAction() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) { _toast('أدخل البريد وكلمة المرور'); return; }
    await _run(() async {
      final auth = context.read<PermissionService>();
      if (_register) {
        await auth.register(email: _email.text, password: _password.text, displayName: _name.text);
      } else {
        await auth.login(userId: _email.text, password: _password.text, provider: 'password');
      }
    });
  }

  Future<void> _phoneAction() async {
    if (_phone.text.trim().isEmpty) { _toast('أدخل رقم الهاتف مع رمز الدولة'); return; }
    if (!_otpSent) {
      await _run(() async { await context.read<PermissionService>().requestPhoneOtp(_phone.text); if (mounted) setState(() => _otpSent = true); });
      return;
    }
    if (_otp.text.trim().isEmpty) { _toast('أدخل رمز التحقق'); return; }
    await _run(() async { await context.read<PermissionService>().login(phone: _phone.text, otp: _otp.text, provider: 'phone'); });
  }

  Future<void> _developerAction() async {
    if (_devCode.text.trim().isEmpty) { _toast('أدخل رمز المطور'); return; }
    await _run(() async { final ok = await context.read<PermissionService>().login(devCode: _devCode.text); if (!ok) throw StateError('رمز المطور غير صحيح.'); });
  }

  Future<void> _biometric() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) { _toast('البصمة/التعرف على الجهاز غير متاح.'); return; }
      final ok = await _localAuth.authenticate(localizedReason: 'افتح جلسة JARVIS المحفوظة');
      if (!ok) return;
      final auth = context.read<PermissionService>();
      if (auth.isAuthenticated) return;
      _toast('لا توجد جلسة محفوظة لفتحها. سجّل الدخول مرة واحدة أولاً.');
    } catch (e) { _toast('تعذر استخدام التحقق الحيوي: $e'); }
  }

  Future<void> _oauth(String provider) async {
    final backend = BackendService.instance;
    if (!backend.configured) { _toast('فعّل JARVIS_BACKEND_URL أولاً.'); return; }
    final uri = Uri.parse('${backend.baseUrl}/auth/oauth/$provider/start?redirect_uri=jarvis://auth');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) _toast('تعذر فتح تسجيل الدخول.');
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try { await action(); } catch (e) { if (mounted) _toast(e.toString().replaceFirst('Bad state: ', '')); } finally { if (mounted) setState(() => _busy = false); }
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Stack(children: [
      Positioned(top: -120, right: -80, child: _glow(260)),
      Positioned(bottom: -140, left: -100, child: _glow(300)),
      Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        const AnimatedJarvisLogo(), const SizedBox(height: 26),
        GoldCard(child: Column(children: [
          const Align(alignment: Alignment.centerRight, child: Text('ابدأ جلستك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(height: 14),
          SegmentedButton<int>(segments: const [
            ButtonSegment(value: 0, label: Text('Email')), ButtonSegment(value: 1, label: Text('هاتف')), ButtonSegment(value: 2, label: Text('مطور')),
          ], selected: {_mode}, onSelectionChanged: (s) => setState(() => _mode = s.first)),
          const SizedBox(height: 14),
          if (_mode == 0) ..._emailFields(),
          if (_mode == 1) ..._phoneFields(),
          if (_mode == 2) ..._developerFields(),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : (_mode == 0 ? _emailAction : _mode == 1 ? _phoneAction : _developerAction), style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, foregroundColor: Colors.black, padding: const EdgeInsets.all(15)), child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : Text(_mode == 1 && !_otpSent ? 'إرسال رمز التحقق' : _register ? 'إنشاء الحساب' : 'دخول إلى JARVIS', style: const TextStyle(fontWeight: FontWeight.w700)))),
          if (_mode == 0) ...[
            TextButton(onPressed: () => setState(() => _register = !_register), child: Text(_register ? 'لديك حساب؟ تسجيل الدخول' : 'إنشاء حساب جديد')),
            const SizedBox(height: 4),
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _oauth('google'), icon: const Icon(Icons.g_mobiledata), label: const Text('Google'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _oauth('apple'), icon: const Icon(Icons.apple), label: const Text('Apple')))]),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _busy ? null : _biometric, icon: const Icon(Icons.fingerprint), label: const Text('فتح بالتحقق الحيوي')),
          ],
        ])),
        const SizedBox(height: 14),
        Text(BackendService.instance.configured ? 'الحسابات والذكاء الاصطناعي يعملان عبر خادم JARVIS الآمن.' : 'نسخة تجريبية: عند ضبط JARVIS_BACKEND_URL تصبح الحسابات والحدود والـAI على الخادم.', textAlign: TextAlign.center, style: const TextStyle(color: JavixColors.textTertiary, fontSize: 11, height: 1.5)),
      ]))),
    ])),
  );

  List<Widget> _emailFields() => [
    if (_register) TextField(controller: _name, textAlign: TextAlign.right, decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined, color: JavixColors.gold), labelText: 'الاسم')), const SizedBox(height: 10),
    TextField(controller: _email, keyboardType: TextInputType.emailAddress, textAlign: TextAlign.right, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, color: JavixColors.gold), labelText: 'البريد الإلكتروني')),
    const SizedBox(height: 10), TextField(controller: _password, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline, color: JavixColors.gold), labelText: 'كلمة المرور', suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility)))),
  ];
  List<Widget> _phoneFields() => [
    TextField(controller: _phone, keyboardType: TextInputType.phone, textAlign: TextAlign.right, decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, color: JavixColors.gold), labelText: 'رقم الهاتف', hintText: '+964...')),
    if (_otpSent) ...[const SizedBox(height: 10), TextField(controller: _otp, keyboardType: TextInputType.number, textAlign: TextAlign.right, decoration: const InputDecoration(prefixIcon: Icon(Icons.password, color: JavixColors.gold), labelText: 'رمز التحقق'))],
  ];
  List<Widget> _developerFields() => [TextField(controller: _devCode, obscureText: _obscure, textAlign: TextAlign.right, decoration: const InputDecoration(prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: JavixColors.gold), labelText: 'رمز المطور'))];
  Widget _glow(double size) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [JavixColors.gold.withValues(alpha: .08), Colors.transparent])));
}
