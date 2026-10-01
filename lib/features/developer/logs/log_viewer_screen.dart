import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../core/theme/javix_theme.dart';

/// Developer-only: rolling diagnostic log viewer.
class LogViewerScreen extends StatelessWidget {
  const LogViewerScreen({super.key});

  static final ListQueue<String> _lines = ListQueue<String>();

  static void log(String line) {
    _lines.addLast('${DateTime.now().toIso8601String()}  $line');
    while (_lines.length > 500) _lines.removeFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجلات التشخيص')),
      body: _lines.isEmpty
          ? const Center(child: Text('لا سجلات بعد', style: TextStyle(color: JavixColors.textTertiary)))
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                final line = _lines.elementAt(_lines.length - 1 - i);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: JavixColors.textSecondary)),
                );
              },
            ),
    );
  }
}
