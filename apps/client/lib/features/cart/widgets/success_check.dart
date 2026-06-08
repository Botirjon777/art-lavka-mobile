import 'dart:math' as math;

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';

/// A checkmark that draws its stroke then bounces in (SPEC §12). Respects the
/// platform "reduce motion" setting (shows the final state instantly).
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, this.size = 96});
  final double size;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduceMotion) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final scale =
            0.6 + 0.4 * Curves.elasticOut.transform(_c.value).clamp(0.0, 1.2);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: _CheckPainter(
                progress: Curves.easeOut.transform(_c.value),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onAccent
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Checkmark points (relative to the circle).
    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.34);

    final firstLen = (p2 - p1).distance;
    final secondLen = (p3 - p2).distance;
    final total = firstLen + secondLen;
    final drawn = total * progress;

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (drawn <= firstLen) {
      final tt = firstLen == 0 ? 0.0 : drawn / firstLen;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * tt, p1.dy + (p2.dy - p1.dy) * tt);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final tt = secondLen == 0
          ? 0.0
          : math.min(1.0, (drawn - firstLen) / secondLen);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * tt, p2.dy + (p3.dy - p2.dy) * tt);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
