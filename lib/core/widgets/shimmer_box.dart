import 'package:flutter/material.dart';

/// A pulsing shimmer placeholder — drop-in replacement for dark containers
/// while thumbnail / cover images are still loading.
///
/// Usage:
/// ```dart
/// item.thumbnail != null
///     ? SafeMemoryImage(bytes: item.thumbnail!, fit: BoxFit.cover)
///     : const ShimmerBox()
/// ```
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.borderRadius = 0,
    this.width,
    this.height,
  });

  final double borderRadius;
  final double? width;
  final double? height;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base      = isDark ? const Color(0xFF1E2028) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF2E3140) : const Color(0xFFF2F2F2);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, _) {
        final x = _shimmer.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
