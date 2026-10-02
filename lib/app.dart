import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/permissions/permission_service.dart';
import 'core/localization/language_service.dart';
import 'core/theme/javix_theme.dart';
import 'data/services/device_service.dart';
import 'data/services/device_status_service.dart';
import 'data/services/ai_service.dart';
import 'data/services/reminder_service.dart';
import 'data/services/search_service.dart';
import 'data/services/speech_service.dart';
import 'data/services/vision_service.dart';
import 'data/services/backend_service.dart';
import 'data/services/subscription_service.dart';
import 'data/services/oauth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/user/home/user_home_screen.dart';
import 'features/developer/dev_dashboard_screen.dart';
import 'features/developer/logs/log_viewer_screen.dart';

/// Root widget. Edition is resolved once from [PermissionService];
/// each edition gets a completely separate navigation tree.
class JavixApp extends StatelessWidget {
  const JavixApp({super.key});
  static bool _oauthStarted = false;

  @override
  Widget build(BuildContext context) {
    if (!_oauthStarted) { _oauthStarted = true; OAuthService.start(); }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(lazy: false, create: (_) => LanguageService()..load()),
        ChangeNotifierProvider.value(value: BackendService.instance..load()),
        ChangeNotifierProvider(create: (_) => PermissionService()..restore()),
        ChangeNotifierProvider(create: (_) => DeviceService()),
        ChangeNotifierProvider(lazy: false, create: (_) => DeviceStatusService()),
        ChangeNotifierProvider(lazy: false, create: (_) => AiService()..load()),
        ChangeNotifierProvider(lazy: false, create: (_) => SubscriptionService()..init()),
        ChangeNotifierProvider(lazy: false, create: (_) => ReminderService()..init()),
        ChangeNotifierProvider(create: (_) => SearchService()),
        ChangeNotifierProvider(lazy: false, create: (_) => SpeechService()..init()),
        ChangeNotifierProvider(create: (_) => VisionService()),
      ],
      child: Consumer<LanguageService>(
        builder: (_, language, __) => MaterialApp(
        title: 'JARVIS',
        debugShowCheckedModeBanner: false,
        theme: JavixTheme.dark,
        locale: language.locale,
        supportedLocales: LanguageService.languages
            .map((item) => Locale(item.code))
            .toList(growable: false),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Consumer<PermissionService>(
          builder: (_, auth, __) {
            if (!auth.restored) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: JavixColors.gold)),
              );
            }
            if (!auth.isAuthenticated) return const LoginScreen();
            LogViewerScreen.log('app: session ${_role(auth)}');
            return auth.isDeveloper
                ? const DevDashboardScreen()
                : const UserHomeScreen();
          },
        ),
      ),
      ),
    );
  }

  String _role(PermissionService auth) =>
      auth.isDeveloper ? 'developer' : 'user';
}
