import 'package:flutter/material.dart';

class AnimatedJarvisText extends StatefulWidget {
  final double fontSize;
  final double letterSpacing;
  final FontWeight fontWeight;
  final bool compact;

  const AnimatedJarvisText({
    super.key,
    this.fontSize = 31,
    this.letterSpacing = 8,
    this.fontWeight = FontWeight.w700,
    this.compact = false,
  });

  @override
  State<AnimatedJarvisText> createState() => _AnimatedJarvisTextState();
}

class _AnimatedJarvisTextState extends State<AnimatedJarvisText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? widget.fontSize * .92 : widget.fontSize;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final shift = (t * 2) - .5;
            return LinearGradient(
              begin: Alignment(-1 + shift, 0),
              end: Alignment(1 + shift, 0),
              colors: const [
                Color(0xFFD4A24E),
                Color(0xFFFFE7A8),
                Color(0xFF8DD7FF),
                Color(0xFFD4A24E),
                Color(0xFFFFD36B),
              ],
              stops: const [0, .22, .48, .72, 1],
            ).createShader(bounds);
          },
          child: Text(
            'JARVIS',
            style: TextStyle(
              fontSize: size,
              letterSpacing: widget.letterSpacing,
              fontWeight: widget.fontWeight,
              shadows: const [
                Shadow(color: Color(0x66D4A24E), blurRadius: 18),
                Shadow(color: Color(0x334BBEFF), blurRadius: 26),
              ],
            ),
          ),
        );
      },
    );
  }
}
