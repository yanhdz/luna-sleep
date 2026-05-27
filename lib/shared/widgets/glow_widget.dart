import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A container with a soft radial glow — used to highlight interactive areas.
class GlowWidget extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double blurRadius;
  final double spreadRadius;

  const GlowWidget({
    super.key,
    required this.child,
    this.glowColor,
    this.blurRadius = 40,
    this.spreadRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = (glowColor ?? AppColors.primary).withAlpha(50);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}
