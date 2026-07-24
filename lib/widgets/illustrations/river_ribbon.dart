import 'package:flutter/material.dart';

/// Декоративная "лента" волны — стилизованный изгиб реки (Иртыш), для
/// фоновых акцентов позади текста. Рисуется тонкими полупрозрачными
/// кривыми линиями с низкой непрозрачностью, чтобы не спорить с контрастом
/// текста, лежащего поверх (см. использование в _HeroHeader/SplashScreen —
/// текст всегда выше по z-order, лента не касается его пикселей).
class RiverRibbon extends StatelessWidget {
  final Color color;
  final double opacity;

  const RiverRibbon({super.key, required this.color, this.opacity = 0.14});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RiverRibbonPainter(color: color, opacity: opacity),
      child: const SizedBox.expand(),
    );
  }
}

class _RiverRibbonPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _RiverRibbonPainter({required this.color, required this.opacity});

  void _drawWave(
      Canvas canvas, double w, double h, double baseY, double amplitude,
      double strokeOpacityFactor) {
    final path = Path()..moveTo(-w * 0.1, baseY);
    path.cubicTo(
      w * 0.2, baseY - amplitude,
      w * 0.4, baseY + amplitude,
      w * 0.6, baseY,
    );
    path.cubicTo(
      w * 0.8, baseY - amplitude,
      w * 1.0, baseY + amplitude,
      w * 1.1, baseY,
    );
    final paint = Paint()
      ..color = color.withValues(alpha: opacity * strokeOpacityFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.10
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawWave(canvas, w, h, h * 0.35, h * 0.10, 1.0);
    _drawWave(canvas, w, h, h * 0.62, h * 0.07, 0.7);
  }

  @override
  bool shouldRepaint(covariant _RiverRibbonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
