import 'package:flutter/material.dart';

import '../core/theme/javix_theme.dart';

class GoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GoldCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JavixColors.surfaceLight.withValues(alpha: .72),
            JavixColors.surface.withValues(alpha: .94),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JavixColors.border),
        boxShadow: [
          BoxShadow(color: JavixColors.gold.withValues(alpha: .025), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: card);
  }
}

class GoldIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const GoldIcon(this.icon, {super.key, this.size = 26});

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: JavixColors.gold);
}
