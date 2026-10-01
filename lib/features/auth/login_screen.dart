import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/strings_ar.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/theme/javix_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userId = TextEditingController();
  final _devCode = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() { _userId.dispose(); _devCode.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_userId.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.loginError))); return; }
    setState(() => _busy = true);
    try {
      await context.read<PermissionService>().login(userId: _userId.text, devCode: _devCode.text.trim().isEmpty ? null : _devCode.text.trim());
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Stack(children: [
      Positioned(top: -120, right: -80, child: _glow(260)),
      Positioned(bottom: -140, left: -100, child: _glow(300)),
      Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        Container(width: 104, height: 104, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: JavixColors.gold, width: 1.8), boxShadow: [BoxShadow(color: JavixColors.gold.withValues(alpha: .16), blurRadius: 34)], gradient: const RadialGradient(colors: [JavixColors.surfaceLight, JavixColors.background])), child: const Center(child: Text('J', style: TextStyle(color: JavixColors.gold, fontSize: 52, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 18),
        const Text('JARVIS', style: TextStyle(fontSize: 31, letterSpacing: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        const Text('YOUR ADVANCED PERSONAL ASSISTANT', style: TextStyle(color: JavixColors.textTertiary, fontSize: 9, letterSpacing: 2.3)),
        const SizedBox(height: 30),
        GoldCard(child: Column(children: [
          const Align(alignment: Alignment.centerRight, child: Text('ابدأ جلستك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          const SizedBox(height: 14),
          TextField(controller: _userId, textAlign: TextAlign.right, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, color: JavixColors.gold), labelText: S.userIdLabel, hintText: S.userIdHint)),
          const SizedBox(height: 12),
          TextField(controller: _devCode, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: JavixColors.gold), labelText: S.devCodeLabel, hintText: S.devCodeHint, suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility)))),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _submit, style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, foregroundColor: Colors.black, padding: const EdgeInsets.all(15)), child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('دخول إلى JARVIS', style: TextStyle(fontWeight: FontWeight.w700)))),
        ])),
        const SizedBox(height: 14),
        const Text('في أول تشغيل سيطلب Android أذونات الميزات المتاحة. يمكنك تغييرها لاحقاً من الأذونات.', textAlign: TextAlign.center, style: TextStyle(color: JavixColors.textTertiary, fontSize: 11, height: 1.5)),
      ]))),
    ])),
  );

  Widget _glow(double size) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [JavixColors.gold.withValues(alpha: .08), Colors.transparent])));
}
