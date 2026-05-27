import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A styled card with optional glow and gradient border.
class LunaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double borderRadius;
  final bool showGlow;
  final Color? glowColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const LunaCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius = 20,
    this.showGlow = false,
    this.glowColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.card;
    final effectiveGlow = glowColor ?? AppColors.primaryGlow;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: effectiveGlow,
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
