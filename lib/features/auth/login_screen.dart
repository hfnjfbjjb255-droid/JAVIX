import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/language_service.dart';
import '../../core/permissions/permission_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  bool _createAccount = false;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final username = _username.text.trim();

    if (username.length < 3) {
      _message('أدخل اسم مستخدم من 3 أحرف على الأقل.');
      return;
    }

    FocusScope.of(context).unfocus();
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
        _message(e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _chooseLanguage() async {
    final service = context.read<LanguageService>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF11151D),
      showDragHandle: true,
      builder: (_) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'اللغات',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          ...LanguageService.languages.map(
            (language) => ListTile(
              leading: Icon(
                language.code == service.locale.languageCode
                    ? Icons.check_circle
                    : Icons.language,
                color: language.code == service.locale.languageCode
                    ? const Color(0xFFD9A441)
                    : Colors.white54,
              ),
              title: Text(language.nativeName),
              subtitle: Text(language.name),
              onTap: () => Navigator.pop(context, language.code),
            ),
          ),
        ],
      ),
    );

    if (selected != null) await service.setLanguage(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10151D),
                  Color(0xFF05070B),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x16000000),
                  Color(0x44000000),
                  Color(0xD9000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: IconButton(
                      tooltip: 'اللغات',
                      onPressed: _chooseLanguage,
                      icon: const Icon(Icons.language, color: Color(0xFFE0BD65)),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: const Color(0xCC080B11),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: const Color(0x55D9A441),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _createAccount
                                        ? 'إنشاء حساب جديد'
                                        : 'تسجيل الدخول',
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF2E4C3),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _username,
                                    enabled: !_busy,
                                    textInputAction: TextInputAction.done,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    onSubmitted: (_) => _submit(),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'اسم المستخدم',
                                      hintText: 'Username',
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: Color(0xFFD9A441),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: FilledButton(
                                      onPressed: _busy ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFD9A441),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
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
                                          : Text(
                                              _createAccount
                                                  ? 'إنشاء الحساب'
                                                  : 'دخول إلى JARVIS',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                              () => _createAccount = !_createAccount,
                                            ),
                                    child: Text(
                                      _createAccount
                                          ? 'لديك حساب؟ تسجيل الدخول'
                                          : 'إنشاء حساب جديد',
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'حساب محلي مؤقت • بدون خادم',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
