import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions/permission_service.dart';
import '../../core/theme/javix_theme.dart';
import '../../widgets/animated_jarvis_logo.dart';
import '../../widgets/gold_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _username.text.trim();

    if (username.isEmpty) {
      _toast('أدخل اسم المستخدم');
      return;
    }

    setState(() => _busy = true);

    try {
      await context.read<PermissionService>().login(userId: username);
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _glow(260),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _glow(300),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const AnimatedJarvisLogo(),
                    const SizedBox(height: 26),
                    GoldCard(
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'ابدأ جلستك',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _username,
                            textAlign: TextAlign.right,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_busy) _login();
                            },
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: JavixColors.gold,
                              ),
                              labelText: 'اسم المستخدم',
                              hintText: 'أدخل اسم المستخدم',
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _login,
                              style: FilledButton.styleFrom(
                                backgroundColor: JavixColors.gold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.all(15),
                              ),
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'دخول إلى JARVIS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'نسخة تجريبية محلية — سجّل الدخول باسم المستخدم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: JavixColors.textTertiary,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            JavixColors.gold.withValues(alpha: .08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
