import 'dart:async';
import 'package:app_links/app_links.dart';
import 'backend_service.dart';

class OAuthService {
  static final AppLinks _links = AppLinks();
  static StreamSubscription<Uri>? _sub;

  static Future<void> start() async {
    await _sub?.cancel();
    _sub = _links.uriLinkStream.listen((uri) async {
      if (uri.scheme != 'jarvis' || uri.host != 'auth') return;
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) await BackendService.instance.setToken(token);
    });
    try {
      final initial = await _links.getInitialLink();
      if (initial != null && initial.scheme == 'jarvis' && initial.host == 'auth') {
        final token = initial.queryParameters['token'];
        if (token != null && token.isNotEmpty) await BackendService.instance.setToken(token);
      }
    } catch (_) {}
  }

  static Future<void> stop() async { await _sub?.cancel(); _sub = null; }
}
