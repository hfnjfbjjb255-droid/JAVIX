import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/javix_theme.dart';
import 'jarvis_core.dart';

/// Subtle animated HUD background. It reacts to the JARVIS core state without
/// stealing attention from the main content.
class JarvisAmbientBackground extends StatefulWidget {
  final JarvisCoreState state;
  const JarvisAmbientBackground({super.key, required this.state});

  @override
  State<JarvisAmbientBackground> createState() => _JarvisAmbientBackgroundState();
}

class _JarvisAmbientBackgroundState extends State<JarvisAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _accent() {
    switch (widget.state) {
      case JarvisCoreState.listening:
        return const Color(0xFF55D6FF);
      case JarvisCoreState.thinking:
        return const Color(0xFFB77CFF);
      case JarvisCoreState.working:
        return JavixColors.gold;
      case JarvisCoreState.completed:
        return JavixColors.success;
      case JarvisCoreState.error:
        return JavixColors.danger;
      case JarvisCoreState.standby:
        return JavixColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _HudPainter(
            progress: _controller.value,
            accent: _accent(),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HudPainter extends CustomPainter {
  final double progress;
  final Color accent;
  const _HudPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .27);
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: .085 + pulse * .035), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * .56));
    canvas.drawCircle(center, size.width * .56, glow);

    final grid = Paint()
      ..color = accent.withValues(alpha: .025)
      ..strokeWidth = 1;
    final step = 42.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final orbit = Paint()
      ..color = accent.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final factor in [.34, .48, .63]) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * factor,
        height: size.width * factor * .55,
      );
      canvas.drawOval(rect, orbit);
    }

    final dotPaint = Paint()..color = accent.withValues(alpha: .30);
    for (var i = 0; i < 24; i++) {
      final seed = i * 17.31;
      final x = (math.sin(seed) + 1) / 2 * size.width;
      final y = ((seed * .37 + progress * size.height) % size.height);
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.5 : .7, dotPaint);
    }

    // Slow cinematic scanner that makes the HUD feel alive without blocking input.
    final sweep = (progress * math.pi * 2) - math.pi / 2;
    final sweepPaint = Paint()
      ..color = accent.withValues(alpha: .075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final sweepRect = Rect.fromCenter(
      center: center,
      width: size.width * .82,
      height: size.width * .82,
    );
    canvas.drawArc(sweepRect, sweep, .38, false, sweepPaint);

    final moving = Offset(
      center.dx + math.cos(sweep) * size.width * .34,
      center.dy + math.sin(sweep) * size.width * .34 * .55,
    );
    final movingGlow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: .18), Colors.transparent],
      ).createShader(Rect.fromCircle(center: moving, radius: 34));
    canvas.drawCircle(moving, 34, movingGlow);
  }

  @override
  bool shouldRepaint(covariant _HudPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
