import 'package:flutter/foundation.dart';

/// Command history used on the home screen ("آخر الأوامر").
class SearchService extends ChangeNotifier {
  final List<({DateTime at, String command, String kind})> _history = [];
  List<({DateTime at, String command, String kind})> get history =>
      List.unmodifiable(_history);

  static const int maxEntries = 50;

  void clear() {
    _history.clear();
    notifyListeners();
  }

  void log(String command, {String kind = 'voice'}) {
    _history.insert(0, (at: DateTime.now(), command: command, kind: kind));
    if (_history.length > maxEntries) _history.removeLast();
    notifyListeners();
  }
}
