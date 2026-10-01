import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/platform/jarvis_platform.dart';
import '../../core/permissions/role.dart';
import '../../features/developer/logs/log_viewer_screen.dart';

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
      _role = (stored == 'developer' && AppConstants.developerBuild) ? Role.developer : Role.user;
      _userId = savedId;
    }
    _restored = true;
    notifyListeners();
  }

  /// Demo login: developers authenticate with a special code.
  Future<bool> login({required String userId, String? devCode}) async {
    // In production: call your backend and verify a signed token instead.
    if (AppConstants.developerBuild &&
        AppConstants.devAccessCode.isNotEmpty &&
        devCode != null &&
        devCode.trim() == AppConstants.devAccessCode) {
      _role = Role.developer;
    } else {
      _role = Role.user;
    }
    _userId = userId.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefRole, _role.edition.name);
    await prefs.setString(AppConstants.prefUserId, _userId!);
    LogViewerScreen.log('login: ${_role.edition.name} ($_userId)');
    notifyListeners();
    return true;
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
