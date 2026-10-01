class AppConstants {
  AppConstants._();

  static const String appName = 'JARVIS';
  static const String appTagline = 'YOUR ADVANCED PERSONAL ASSISTANT';

  static const Duration defaultReminderLead = Duration(minutes: 30);

  static const String prefRole = 'javix_role';
  static const String prefUserId = 'javix_user_id';
  static const String prefReadAloud = 'javix_read_aloud';
  static const String prefLeadMinutes = 'javix_lead_minutes';
  static const String prefReminders = 'javix_reminders';
  static const String prefPermissionsRequested = 'jarvis_permissions_requested';

  // Developer access is supplied at build time. Never ship a production
  // secret in the Dart source; real authorization must still be server-side.
  static const String devAccessCode =
      String.fromEnvironment('JAVIX_DEV_CODE', defaultValue: '');
  static const bool developerBuild =
      bool.fromEnvironment('JAVIX_DEVELOPER_BUILD', defaultValue: false);

  static const String mqttDefaultHost = '192.168.1.10';
  static const int mqttDefaultPort = 1883;
}
