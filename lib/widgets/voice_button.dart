import 'package:flutter/material.dart';

import '../core/theme/javix_theme.dart';

/// The central gold microphone ring shown on the home screen.
/// [size] is configurable so the button adapts to narrow screens.
class VoiceButton extends StatelessWidget {
  final bool listening;
  final VoidCallback onTap;
  final double size;

  const VoiceButton({
    super.key,
    required this.listening,
    required this.onTap,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: JavixColors.gold,
            width: listening ? 5 : 2.5,
          ),
          boxShadow: listening
              ? [BoxShadow(color: JavixColors.gold.withOpacity(0.35), blurRadius: 40)]
              : [],
        ),
        child: Center(
          child: Icon(
            Icons.graphic_eq,
            size: size * 0.31,
            color: listening ? JavixColors.gold : JavixColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
