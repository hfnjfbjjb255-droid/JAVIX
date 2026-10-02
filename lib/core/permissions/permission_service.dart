import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/platform/jarvis_platform.dart';
import '../../features/developer/logs/log_viewer_screen.dart';
import 'role.dart';

class PermissionService extends ChangeNotifier {
  Role _role = Role.user;
  String? _userId;
  bool _restored = false;

  Role get role => _role;
  bool get isDeveloper => _role.edition == AppEdition.developer;
  String? get userId => _userId;
  bool get isAuthenticated => _userId != null;
  bool get restored => _restored;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    final permissionsRequested =
        prefs.getBool(AppConstants.prefPermissionsRequested) ?? false;

    if (!permissionsRequested) {
      try {
        await JarvisPlatform.requestAllRelevantPermissions();
        await prefs.setBool(
          AppConstants.prefPermissionsRequested,
          true,
        );
      } catch (_) {
        // Permission requests are best-effort. The permissions screen
        // remains available if Android blocks or delays the request.
      }
    }

    final storedRole = prefs.getString(AppConstants.prefRole);
    final savedId = prefs.getString(AppConstants.prefUserId);
    final localUsername =
        prefs.getString(AppConstants.prefLocalUsername);

    if (savedId != null && savedId.trim().isNotEmpty) {
      _role = storedRole == 'developer' && AppConstants.developerBuild
          ? Role.developer
          : Role.user;
      _userId = savedId;
    } else if (localUsername != null && localUsername.trim().isNotEmpty) {
      _role = Role.user;
      _userId = localUsername.trim();
      await prefs.setString(
        AppConstants.prefRole,
        _role.edition.name,
      );
      await prefs.setString(
        AppConstants.prefUserId,
        _userId!,
      );
    }

    _restored = true;
    notifyListeners();
  }

  Future<bool> login({
    String userId = '',
    String? devCode,
    String? password,
    String? phone,
    String? otp,
    String provider = 'password',
  }) async {
    final normalizedCode = devCode?.trim() ?? '';

    final developerLogin = AppConstants.developerBuild &&
        AppConstants.devAccessCode.isNotEmpty &&
        normalizedCode.isNotEmpty &&
        normalizedCode == AppConstants.devAccessCode;

    if (developerLogin) {
      _role = Role.developer;
      _userId = 'Developer';
    } else {
      final username = userId.trim();
      if (username.isEmpty) {
        throw StateError('أدخل اسم المستخدم.');
      }

      final prefs = await SharedPreferences.getInstance();
      final savedUsername =
          prefs.getString(AppConstants.prefLocalUsername);

      if (savedUsername == null || savedUsername.trim().isEmpty) {
        throw StateError('لا يوجد حساب محلي. أنشئ حسابًا أولاً.');
      }

      if (savedUsername.trim().toLowerCase() != username.toLowerCase()) {
        throw StateError('اسم المستخدم غير صحيح.');
      }

      _role = Role.user;
      _userId = savedUsername.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefRole, _role.edition.name);
    await prefs.setString(AppConstants.prefUserId, _userId!);

    LogViewerScreen.log(
      'login: ${_role.edition.name} ($_userId)',
    );
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final username = (displayName ?? email).trim();

    if (username.length < 3) {
      throw StateError(
        'اسم المستخدم يجب أن يحتوي على 3 أحرف على الأقل.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final existing =
        prefs.getString(AppConstants.prefLocalUsername);

    if (existing != null && existing.trim().isNotEmpty) {
      throw StateError('يوجد حساب محلي مسجل على هذا الجهاز.');
    }

    await prefs.setString(
      AppConstants.prefLocalUsername,
      username,
    );

    _role = Role.user;
    _userId = username;

    await prefs.setString(
      AppConstants.prefRole,
      _role.edition.name,
    );
    await prefs.setString(
      AppConstants.prefUserId,
      _userId!,
    );

    LogViewerScreen.log(
      'register: ${_role.edition.name} ($_userId)',
    );
    notifyListeners();
    return true;
  }

  Future<void> requestPhoneOtp(String phone) async {
    throw StateError(
      'تسجيل الهاتف سيكون متاحًا بعد ربط خادم JARVIS.',
    );
  }

  Future<void> logout() async {
    LogViewerScreen.log('logout: $_userId');

    _role = Role.user;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefRole);
    await prefs.remove(AppConstants.prefUserId);

    notifyListeners();
  }

  void require(AppPermission p) {
    if (!_role.can(p)) {
      throw PermissionDeniedException(p);
    }
  }
}

class PermissionDeniedException implements Exception {
  final AppPermission permission;

  PermissionDeniedException(this.permission);

  @override
  String toString() => 'Permission denied: $permission';
}
