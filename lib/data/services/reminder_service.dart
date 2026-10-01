import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants.dart';
import '../../features/developer/logs/log_viewer_screen.dart';
import '../models/reminder.dart';

/// Persists reminders locally and schedules their notifications.
class ReminderService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final List<Reminder> _reminders = [];
  List<Reminder> get reminders => List.unmodifiable(_reminders);

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: android),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.prefReminders) ?? const [];
    _reminders
      ..clear()
      ..addAll(raw.map((item) {
        try {
          return Reminder.fromMap(
              Map<String, dynamic>.from(jsonDecode(item) as Map));
        } catch (_) {
          return null;
        }
      }).whereType<Reminder>());

    // One-shot notifications are already persisted by Android, but any
    // future reminders missing from the platform scheduler are restored here.
    for (final reminder in List<Reminder>.from(_reminders)) {
      if (reminder.id != null) {
        await _schedule(reminder);
      }
    }
    notifyListeners();
  }

  Future<int> add(Reminder r) async {
    final alertAt = r.alertAt;
    if (!r.repeatDaily && !alertAt.isAfter(DateTime.now())) {
      throw ArgumentError('وقت التنبيه يجب أن يكون في المستقبل');
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stored = Reminder(
      id: id,
      title: r.title,
      dueAt: r.dueAt,
      leadTime: r.leadTime,
      repeatDaily: r.repeatDaily,
    );

    _reminders.add(stored);
    await _save();
    await _schedule(stored);
    notifyListeners();
    return id;
  }

  Future<void> remove(int id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _notifications.cancel(id);
    await _save();
    LogViewerScreen.log('reminder cancelled: $id');
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.prefReminders,
      _reminders.map((r) => jsonEncode(r.toMap())).toList(),
    );
  }

  Future<void> _schedule(Reminder r) async {
    if (r.id == null) return;

    var scheduled = tz.TZDateTime.from(r.alertAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (r.repeatDaily) {
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else if (!scheduled.isAfter(now)) {
      LogViewerScreen.log('reminder skipped because alert is in the past: ${r.id}');
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'javix_reminders',
        'التذكيرات',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    LogViewerScreen.log(
      'reminder scheduled: ${r.title} at $scheduled (${tz.local.name})',
    );

    await _notifications.zonedSchedule(
      r.id!,
      'تذكير: ${r.title}',
      'الموعد ${r.dueAt.hour}:${r.dueAt.minute.toString().padLeft(2, '0')}',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          r.repeatDaily ? DateTimeComponents.time : null,
    );
  }
}
