import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  // Use the device local timezone so reminders fire at the right local time.
  // flutter_timezone would detect it automatically; until it's added we pin
  // the app's primary zone and fall back to UTC rather than staying on it.
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
  } catch (_) {
    // Keep UTC if the zone database is unavailable.
  }
  runApp(const JavixApp());
}
