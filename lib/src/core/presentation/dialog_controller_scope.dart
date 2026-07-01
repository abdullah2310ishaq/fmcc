import 'package:flutter/material.dart';

/// Owns [TextEditingController]s for the lifetime of a dialog route.
///
/// Disposes controllers when the dialog widget is removed from the tree, so
/// callers must not dispose them after [showDialog] returns.
class DialogControllerScope extends StatefulWidget {
  const DialogControllerScope({
    super.key,
    required this.controllerCount,
    required this.builder,
  });

  final int controllerCount;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> controllers,
  ) builder;

  @override
  State<DialogControllerScope> createState() => _DialogControllerScopeState();
}

class _DialogControllerScopeState extends State<DialogControllerScope> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.controllerCount,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}
