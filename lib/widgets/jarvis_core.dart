import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/javix_theme.dart';

/// The central JARVIS nucleus. It communicates the assistant's current state
/// visually so the app feels alive even while a remote AI task is processing.
enum JarvisCoreState {
  standby,
  listening,
  thinking,
  working,
  completed,
  error,
}

class JarvisCore extends StatefulWidget {
  final JarvisCoreState state;
  final double size;
  final VoidCallback? onTap;
  final bool compact;

  const JarvisCore({
    super.key,
    required this.state,
    this.size = 190,
    this.onTap,
    this.compact = false,
  });

  @override
  State<JarvisCore> createState() => _JarvisCoreState();
}

class _JarvisCoreState extends State<JarvisCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  JarvisCoreState? _lastState;

  @override
  void didUpdateWidget(covariant JarvisCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastState != widget.state) {
      _lastState = widget.state;
      HapticFeedback.selectionClick();
      if (widget.state == JarvisCoreState.error) {
        SystemSound.play(SystemSoundType.alert);
      } else if (widget.state == JarvisCoreState.completed ||
          widget.state == JarvisCoreState.listening) {
        SystemSound.play(SystemSoundType.click);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _CoreStyle get _style {
    switch (widget.state) {
      case JarvisCoreState.listening:
        return const _CoreStyle(
          color: Color(0xFF55D6FF),
          glow: Color(0x6655D6FF),
          icon: Icons.mic_none_rounded,
          label: 'Listening',
          arabic: 'أستمع إليك',
        );
      case JarvisCoreState.thinking:
        return const _CoreStyle(
          color: Color(0xFFB77CFF),
          glow: Color(0x66B77CFF),
          icon: Icons.psychology_outlined,
          label: 'Thinking',
          arabic: 'أفكر',
        );
      case JarvisCoreState.working:
        return const _CoreStyle(
          color: JavixColors.gold,
          glow: Color(0x66D4A24E),
          icon: Icons.settings_outlined,
          label: 'Working',
          arabic: 'أنفذ المهمة',
        );
      case JarvisCoreState.completed:
        return const _CoreStyle(
          color: JavixColors.success,
          glow: Color(0x664CAF7D),
          icon: Icons.check_rounded,
          label: 'Completed',
          arabic: 'اكتملت المهمة',
        );
      case JarvisCoreState.error:
        return const _CoreStyle(
          color: JavixColors.danger,
          glow: Color(0x66E05C5C),
          icon: Icons.warning_amber_rounded,
          label: 'Error',
          arabic: 'حدث خطأ',
        );
      case JarvisCoreState.standby:
        return const _CoreStyle(
          color: JavixColors.gold,
          glow: Color(0x44D4A24E),
          icon: Icons.graphic_eq_rounded,
          label: 'JARVIS READY',
          arabic: 'جاهز لأمرك',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.compact ? widget.size * .82 : widget.size;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: diameter + 34,
        height: diameter + 34,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * math.pi * 2;
            final pulse = (math.sin(t) + 1) / 2;
            final speed = widget.state == JarvisCoreState.working ||
                    widget.state == JarvisCoreState.thinking
                ? 1.7
                : 1.0;
            final rotation = t * speed;
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: diameter + 26,
                    height: diameter + 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _style.color.withValues(alpha: .18),
                        width: 1,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _OrbitPainter(
                        color: _style.color,
                        progress: _controller.value,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _style.color.withValues(alpha: .20 + pulse * .08),
                        JavixColors.surface,
                        JavixColors.background,
                      ],
                      stops: const [0, .55, 1],
                    ),
                    border: Border.all(
                      color: _style.color.withValues(alpha: .78),
                      width: widget.state == JarvisCoreState.error ? 2.5 : 1.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _style.glow,
                        blurRadius: 24 + pulse * 22,
                        spreadRadius: 1 + pulse * 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: diameter * .72,
                        height: diameter * .72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _style.color.withValues(alpha: .22),
                          ),
                        ),
                      ),
                      Icon(
                        _style.icon,
                        size: diameter * .25,
                        color: _style.color,
                      ),
                      Positioned(
                        bottom: diameter * .17,
                        child: Column(
                          children: [
                            Text(
                              _style.label,
                              style: TextStyle(
                                color: _style.color,
                                fontSize: widget.compact ? 8 : 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _style.arabic,
                              style: const TextStyle(
                                color: JavixColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CoreStyle {
  final Color color;
  final Color glow;
  final IconData icon;
  final String label;
  final String arabic;

  const _CoreStyle({
    required this.color,
    required this.glow,
    required this.icon,
    required this.label,
    required this.arabic,
  });
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _OrbitPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color.withValues(alpha: .75)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 3; i++) {
      final angle = progress * math.pi * 2 + i * math.pi * 2 / 3;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(point, i == 0 ? 3.2 : 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
