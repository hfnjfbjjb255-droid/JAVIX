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
  Future<bool> login({String userId = '', String? devCode, String? password, String? phone, String? otp, String provider = 'password'}) async {
    final normalizedCode = devCode?.trim() ?? '';
    final developerLogin = AppConstants.developerBuild &&
        AppConstants.devAccessCode.isNotEmpty &&
        normalizedCode.isNotEmpty &&
        normalizedCode == AppConstants.devAccessCode;
    if (developerLogin) {
      _role = Role.developer;
      _userId = 'Developer';
    } else if (BackendService.instance.configured) {
      final body = <String, dynamic>{
        'provider': provider,
        'identifier': userId.trim(),
        'password': password ?? '',
        'phone': phone ?? '',
        'otp': otp ?? '',
      };
      final result = await BackendService.instance.post('/auth/login', body, auth: false);
      final token = result['token']?.toString() ?? '';
      final account = result['user'] is Map ? Map<String, dynamic>.from(result['user']) : <String, dynamic>{};
      if (token.isEmpty) throw StateError('لم يرجع الخادم جلسة دخول صالحة.');
      await BackendService.instance.setToken(token);
      final role = account['role']?.toString() ?? 'user';
      _role = role == 'developer' ? Role.developer : Role.user;
      _userId = (account['id'] ?? account['email'] ?? account['phone'] ?? userId).toString();
    } else {
      final localUser = userId.trim();
      if (localUser.isEmpty) {
        throw StateError('أدخل اسم المستخدم.');
      }
      _role = Role.user;
      _userId = localUser;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefRole, _role.edition.name);
    await prefs.setString(AppConstants.prefUserId, _userId!);
    LogViewerScreen.log('login: ${_role.edition.name} ($_userId)');
    notifyListeners();
    return true;
  }

  Future<bool> register({required String email, required String password, String? displayName}) async {
    if (!BackendService.instance.configured) throw StateError('الخادم غير مهيأ.');
    final result = await BackendService.instance.post('/auth/register', {
      'email': email.trim(), 'password': password, 'displayName': displayName?.trim() ?? '',
    }, auth: false);
    final token = result['token']?.toString() ?? '';
    if (token.isEmpty) throw StateError('فشل إنشاء الحساب.');
    await BackendService.instance.setToken(token);
    final account = result['user'] is Map ? Map<String, dynamic>.from(result['user']) : <String, dynamic>{};
    _role = Role.user;
    _userId = (account['id'] ?? account['email'] ?? email).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefRole, _role.edition.name);
    await prefs.setString(AppConstants.prefUserId, _userId!);
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
