import 'package:flutter/material.dart';

/// Consistent system inset handling for doctor UI.
abstract final class DoctorInsets {
  DoctorInsets._();

  static double top(BuildContext context) => MediaQuery.paddingOf(context).top;

  static double bottom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  /// Extra scroll padding on full-screen routes (home indicator + breathing room).
  static double scrollBottom(BuildContext context, {double extra = 24}) =>
      bottom(context) + extra;
}

/// Body of a [DoctorShell] tab — top inset only; bottom nav sits outside the body.
class DoctorTabSafeArea extends StatelessWidget {
  const DoctorTabSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(bottom: false, child: child);
  }
}

/// Full-screen doctor route without bottom navigation.
class DoctorPageSafeArea extends StatelessWidget {
  const DoctorPageSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: child);
  }
}

/// Bottom inset for fixed footers (prescription bar, etc.).
class DoctorBottomInset extends StatelessWidget {
  const DoctorBottomInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bottom = DoctorInsets.bottom(context);
    return Padding(
      padding: padding.copyWith(bottom: padding.bottom + bottom),
      child: child,
    );
  }
}

/// Top inset for edge-to-edge gradient headers (status bar / notch).
class DoctorTopInset extends StatelessWidget {
  const DoctorTopInset({
    super.key,
    required this.child,
    this.extraTop = 4,
  });

  final Widget child;
  final double extraTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: DoctorInsets.top(context) + extraTop),
      child: child,
    );
  }
}
