import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme/app_colors.dart';

/// Modern Medical Card with Glassmorphism option
class MedicalCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showBorder;
  final Color? borderColor;
  final bool isGlass;
  final Gradient? gradient;

  const MedicalCard({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.titleIconColor,
    this.trailing,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.showBorder = false,
    this.borderColor,
    this.isGlass = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(titleIcon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(title!, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );

    final decoration = BoxDecoration(
      color: isGlass ? null : (backgroundColor ?? AppColors.cardBackground),
      gradient: gradient ?? (isGlass ? AppColors.glassGradient : null),
      borderRadius: BorderRadius.circular(20),
      border: showBorder || isGlass ? Border.all(color: borderColor ?? (isGlass ? AppColors.glassBorder : AppColors.border)) : null,
      boxShadow: isGlass ? null : [
        BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: const Offset(0, 8)),
        BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 40, spreadRadius: -10),
      ],
    );

    Widget card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: isGlass
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: cardContent),
                )
              : cardContent,
        ),
      ),
    );

    return card;
  }
}

/// Modern Stat Card with Gradient and Glow
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Gradient? gradient;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.hasGlow = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppColors.cardBackground) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: const Offset(0, 8)),
          if (hasGlow) BoxShadow(color: iconColor.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gradient != null ? Colors.white.withValues(alpha: 0.2) : iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: gradient != null ? Colors.white : iconColor, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: gradient != null ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: gradient != null ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Timeline Card for Medical Records
class TimelineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final IconData icon;
  final Color iconColor;
  final Widget? expandedContent;
  final bool isExpanded;
  final VoidCallback? onTap;

  const TimelineCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.iconColor,
    this.expandedContent,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? iconColor.withValues(alpha: 0.3) : AppColors.border),
        boxShadow: isExpanded ? [BoxShadow(color: iconColor.withValues(alpha: 0.15), blurRadius: 20)] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [iconColor, iconColor.withValues(alpha: 0.7)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(date, style: Theme.of(context).textTheme.labelSmall),
                        if (expandedContent != null) ...[
                          const SizedBox(height: 4),
                          Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
                        ],
                      ],
                    ),
                  ],
                ),
                if (isExpanded && expandedContent != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: expandedContent!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
