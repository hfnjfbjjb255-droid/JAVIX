import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions/permission_service.dart';
import '../../core/theme/javix_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();

  late final AnimationController _animation;

  bool _busy = false;
  bool _createAccount = false;

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();

    if (username.isEmpty) {
      _toast('أدخل اسم المستخدم');
      return;
    }

    setState(() => _busy = true);

    try {
      final auth = context.read<PermissionService>();

      if (_createAccount) {
        await auth.register(
          email: username,
          password: '',
          displayName: username,
        );
      } else {
        await auth.login(userId: username);
      }
    } catch (e) {
      if (mounted) {
        _toast(
          e.toString().replaceFirst('Bad state: ', ''),
        );
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/jarvis_login.jpg',
            fit: BoxFit.cover,
          ),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x99000000),
                  Color(0xDD000000),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final glow = 0.35 + (_animation.value * 0.35);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 1.0 + (_animation.value * 0.025),
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFFFE7A0),
                                  Color(0xFFD6A83D),
                                  Color(0xFFFFF1B8),
                                  Color(0xFF9C6B16),
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'JARVIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 54,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 8,
                                shadows: [
                                  Shadow(
                                    color: JavixColors.gold.withValues(
                                      alpha: glow,
                                    ),
                                    blurRadius: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'YOUR AI ASSISTANT',
                          style: TextStyle(
                            color: Color(0xFFD8D0C0),
                            fontSize: 11,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 48),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 14,
                              sigmaY: 14,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .48),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: JavixColors.gold.withValues(
                                    alpha: .32,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: JavixColors.gold.withValues(
                                      alpha: glow * .16,
                                    ),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _username,
                                    enabled: !_busy,
                                    textAlign: TextAlign.right,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (!_busy) _submit();
                                    },
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'اسم المستخدم',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFFD5C28D),
                                      ),
                                      hintText: 'Username',
                                      hintStyle: const TextStyle(
                                        color: Colors.white38,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: JavixColors.gold,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: .06,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: FilledButton(
                                      onPressed:
                                          _busy ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            JavixColors.gold,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Text(
                                              _createAccount
                                                  ? 'إنشاء الحساب'
                                                  : 'دخول إلى JARVIS',
                                              style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () {
                                            setState(() {
                                              _createAccount =
                                                  !_createAccount;
                                            });
                                          },
                                    child: Text(
                                      _createAccount
                                          ? 'لديك حساب؟ تسجيل الدخول'
                                          : 'إنشاء حساب جديد',
                                      style: const TextStyle(
                                        color: Color(0xFFE2C56A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'LOCAL MODE • NO SERVER CONNECTION',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
