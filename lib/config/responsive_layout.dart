import 'package:flutter/material.dart';

/// Breakpoints (matches Material 3 guidelines)
/// mobile  : < 600
/// tablet  : 600 – 1023
/// desktop : ≥ 1024
class Bp {
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Quick screen-width helpers available anywhere via BuildContext.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < Bp.mobile;
  bool get isTablet => screenWidth >= Bp.mobile && screenWidth < Bp.tablet;
  bool get isDesktop => screenWidth >= Bp.tablet;
  bool get isNarrow => screenWidth < Bp.mobile; // alias

  /// Responsive padding — tighter on small screens
  EdgeInsets get pagePadding => isMobile
      ? const EdgeInsets.all(14)
      : isTablet
          ? const EdgeInsets.all(20)
          : const EdgeInsets.all(24);

  /// Responsive horizontal padding only
  EdgeInsets get hPadding => isMobile
      ? const EdgeInsets.symmetric(horizontal: 14)
      : const EdgeInsets.symmetric(horizontal: 24);

  /// Font scale factor
  double get fontScale => isMobile ? 0.85 : 1.0;

  /// Dialog width — never exceeds screen width minus safe margins
  double get dialogWidth =>
      (screenWidth - 48).clamp(280.0, 520.0);

  /// How many columns to show in a grid given a preferred item width
  int gridColumns(double preferredItemWidth) =>
      (screenWidth / preferredItemWidth).floor().clamp(1, 6);
}

// ─────────────────────────────────────────────────────────────────────────────
// Adaptive layout widget — Row on wide screens, Column on narrow ones
// ─────────────────────────────────────────────────────────────────────────────
class AdaptiveRowCol extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const AdaptiveRowCol({
    super.key,
    required this.children,
    this.breakpoint = Bp.mobile,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          // Stack vertically
          final spaced = <Widget>[];
          for (var i = 0; i < children.length; i++) {
            spaced.add(children[i]);
            if (i < children.length - 1) {
              spaced.add(SizedBox(height: spacing));
            }
          }
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            children: spaced,
          );
        }
        // Side by side
        final spaced = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          spaced.add(children[i]);
          if (i < children.length - 1) {
            spaced.add(SizedBox(width: spacing));
          }
        }
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: spaced,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive page header — title + optional action button
// On mobile the button wraps below the title
// ─────────────────────────────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF182B68),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(color: Color(0xFF6C757D), fontSize: 13),
          ),
      ],
    );

    if (action == null) return titleWidget;

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 10),
          action!,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleWidget),
        action!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive KPI row — wraps to multiple rows on mobile
// ─────────────────────────────────────────────────────────────────────────────
class KpiRow extends StatelessWidget {
  final List<Widget> kpis;
  const KpiRow({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      // 2 per row on mobile
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: kpis
            .map((k) => SizedBox(
                  width: (context.screenWidth - 42) / 2,
                  child: k,
                ))
            .toList(),
      );
    }
    return Row(
      children: kpis
          .expand((k) => [Expanded(child: k), const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive dialog helper
// ─────────────────────────────────────────────────────────────────────────────
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveDialog({super.key, required this.child, this.maxWidth = 520});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (context.screenWidth - 48).clamp(280.0, maxWidth),
        ),
        child: child,
      ),
    );
  }
}
