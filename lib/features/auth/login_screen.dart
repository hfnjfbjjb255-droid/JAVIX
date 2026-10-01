import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/strings_ar.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/theme/javix_theme.dart';

/// The entry point of the app: every session starts here.
/// Entering the developer code unlocks the Developer Edition.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userId = TextEditingController();
  final _devCode = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _userId.dispose();
    _devCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_userId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.loginError)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<PermissionService>().login(
            userId: _userId.text,
            devCode: _devCode.text.isEmpty ? null : _devCode.text,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: JavixColors.gold, width: 2),
                ),
                child: const Center(
                  child: Text('J', style: TextStyle(color: JavixColors.gold, fontSize: 40, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('JAVIX', style: TextStyle(letterSpacing: 8, fontSize: 26, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text(S.loginSubtitle, style: TextStyle(color: JavixColors.textSecondary)),
              const SizedBox(height: 32),
              TextField(
                controller: _userId,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: S.userIdLabel, hintText: S.userIdHint),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _devCode,
                obscureText: true,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: S.devCodeLabel, hintText: S.devCodeHint),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(16)),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text(S.loginButton, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
