import 'package:flutter/material.dart';

/// Стилизованный геометрический знак — силуэт крепостной башни (по мотивам
/// исторической Омской крепости, ядра города). Не буквальная копия герба,
/// а упрощённый бренд-знак: тело башни + зубцы-мерлоны + узкая бойница.
/// Рисуется CustomPainter, без внешних SVG/PNG-файлов — тот же принцип,
/// что уже применяется в EmptyStateWidget (декоративная композиция
/// штатными виджетами Flutter).
class FortressMark extends StatelessWidget {
  final double size;
  final Color color;

  const FortressMark({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FortressPainter(color: color)),
    );
  }
}

class _FortressPainter extends CustomPainter {
  final Color color;

  _FortressPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Тело башни.
    final bodyRect = Rect.fromLTWH(w * 0.24, h * 0.40, w * 0.52, h * 0.60);
    canvas.drawRect(bodyRect, paint);

    // Зубцы (мерлоны) — три блока вдоль верхнего края тела башни, флюсом
    // к его левому/правому краю, с двумя равными промежутками между ними.
    const merlonWidth = 0.13;
    final merlonXs = [w * 0.24, w * 0.435, w * 0.63];
    for (final x in merlonXs) {
      canvas.drawRect(
        Rect.fromLTWH(x, h * 0.28, w * merlonWidth, h * 0.12),
        paint,
      );
    }

    // Узкая бойница — вертикальная прорезь в теле башни, светлее основного
    // цвета (не вырез "в фон" — фон под маркой не всегда известен заранее).
    final slitPaint = Paint()..color = color.withValues(alpha: 0.35);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.47, h * 0.55, w * 0.06, h * 0.28),
      slitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FortressPainter oldDelegate) =>
      oldDelegate.color != color;
}
