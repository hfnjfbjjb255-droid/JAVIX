import 'package:flutter/material.dart';

import '../core/theme/javix_theme.dart';
import 'animated_jarvis_text.dart';

class AnimatedJarvisLogo extends StatelessWidget {
  final double textSize;
  final bool showTagline;
  const AnimatedJarvisLogo({super.key, this.textSize = 31, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: textSize * 3.2,
          height: textSize * 3.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: JavixColors.gold, width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x44D4A24E), blurRadius: 30)],
            gradient: const RadialGradient(colors: [JavixColors.surfaceLight, JavixColors.background]),
          ),
          child: const Center(child: Text('J', style: TextStyle(color: JavixColors.gold, fontSize: 48, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 16),
        AnimatedJarvisText(fontSize: textSize),
        if (showTagline) ...[
          const SizedBox(height: 6),
          const Text('YOUR ADVANCED PERSONAL ASSISTANT', style: TextStyle(color: JavixColors.textTertiary, fontSize: 9, letterSpacing: 2.2)),
        ],
      ],
    );
  }
}
