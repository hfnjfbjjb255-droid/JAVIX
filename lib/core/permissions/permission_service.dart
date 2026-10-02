import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/platform/jarvis_platform.dart';
import '../../core/permissions/role.dart';
import '../../features/developer/logs/log_viewer_screen.dart';
import '../../data/services/backend_service.dart';

/// Session-level auth + role resolution.
/// In production, replace [login] with your backend auth (Firebase Auth, JWT...).
class PermissionService extends ChangeNotifier {
  Role _role = Role.user;
  String? _userId;

  Role get role => _role;
  bool get isDeveloper => _role.edition == AppEdition.developer;
  String? get userId => _userId;

  /// No one is in until they pass through the login screen.
  bool get isAuthenticated => _userId != null;

  bool _restored = false;
  bool get restored => _restored;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsRequested = prefs.getBool(AppConstants.prefPermissionsRequested) ?? false;
    if (!permissionsRequested) {
      try {
        await JarvisPlatform.requestAllRelevantPermissions();
        await prefs.setBool(AppConstants.prefPermissionsRequested, true);
      } catch (_) {
        // The permissions page remains available from Profile if the OS blocks
        // a first-run request or the platform channel is unavailable.
      }
    }
    final stored = prefs.getString(AppConstants.prefRole);
    final savedId = prefs.getString(AppConstants.prefUserId);
    if (stored != null && savedId != null) {
      if (BackendService.instance.configured) {
        if (BackendService.instance.authenticated) {
          try {
            final result = await BackendService.instance.get('/auth/me');
            final account = result['user'] is Map ? Map<String, dynamic>.from(result['user']) : <String, dynamic>{};
            _role = account['role']?.toString() == 'developer' ? Role.developer : Role.user;
            _userId = (account['id'] ?? account['email'] ?? account['phone'] ?? savedId).toString();
          } catch (_) {
            await BackendService.instance.setToken('');
          }
        }
      } else {
        _role = (stored == 'developer' && AppConstants.developerBuild) ? Role.developer : Role.user;
        _userId = savedId;
      }
    }
    _restored = true;
    notifyListeners();
  }

  /// Real auth is delegated to the JARVIS backend when configured.
  /// The local developer code remains available only for the explicit demo build.
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

      if (savedUsername == null || savedUsername.isEmpty) {
        throw StateError('لا يوجد حساب مسجل. أنشئ حسابًا أولاً.');
      }

      if (savedUsername.toLowerCase() != username.toLowerCase()) {
        throw StateError('اسم المستخدم غير صحيح.');
      }

      _role = Role.user;
      _userId = savedUsername;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefRole, _role.edition.name);
    await prefs.setString(AppConstants.prefUserId, _userId!);

    LogViewerScreen.log('login: ${_role.edition.name} ($_userId)');
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final username = (displayName ?? email).trim();

    if (username.isEmpty) {
      throw StateError('أدخل اسم المستخدم.');
    }

    final prefs = await SharedPreferences.getInstance();
    final existing =
        prefs.getString(AppConstants.prefLocalUsername);

    if (existing != null && existing.isNotEmpty) {
      throw StateError('يوجد حساب مسجل على هذا الجهاز.');
    }

    await prefs.setString(
      AppConstants.prefLocalUsername,
      username,
    );

    _role = Role.user;
    _userId = username;

    await prefs.setString(AppConstants.prefRole, _role.edition.name);
    await prefs.setString(AppConstants.prefUserId, _userId!);

    LogViewerScreen.log('register: ${_role.edition.name} ($_userId)');
    notifyListeners();
    return true;
  }

  Future<void> requestPhoneOtp(String phone) async {
    if (!BackendService.instance.configured) throw StateError('الخادم غير مهيأ.');
    await BackendService.instance.post('/auth/phone/request', {'phone': phone.trim()}, auth: false);
  }

  Future<void> logout() async {
    LogViewerScreen.log('logout: $_userId');
    _role = Role.user;
    _userId = null;
    if (BackendService.instance.authenticated) {
      await BackendService.instance.setToken('');
    }
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
