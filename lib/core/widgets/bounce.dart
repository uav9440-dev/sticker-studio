import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// لمسة حركية موحّدة: أي عنصر يُضغط ينكمش قليلًا مع اهتزاز خفيف ثم يرتد.
class Bounce extends StatefulWidget {
  const Bounce({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<Bounce> createState() => _BounceState();
}

class _BounceState extends State<Bounce> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.enabled ? 1 : 0.35,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                HapticFeedback.selectionClick();
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
