import 'package:flutter/material.dart';

/// Редкие штрихи травы вдоль нижнего края — лёгкая текстура-отсылка к
/// степному ландшафту региона, используется как тонкий акцент внутри
/// декоративной композиции пустых состояний (см. EmptyStateWidget). Число
/// штрихов и непрозрачность намеренно небольшие — не должно читаться как
/// узор/паттерн, только едва заметная деталь.
class SteppeTexture extends StatelessWidget {
  final Color color;
  final int bladeCount;

  const SteppeTexture({super.key, required this.color, this.bladeCount = 7});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SteppeTexturePainter(color: color, bladeCount: bladeCount),
      child: const SizedBox.expand(),
    );
  }
}

class _SteppeTexturePainter extends CustomPainter {
  final Color color;
  final int bladeCount;

  _SteppeTexturePainter({required this.color, required this.bladeCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;

    final baseY = size.height * 0.92;
    for (var i = 0; i < bladeCount; i++) {
      final t = bladeCount == 1 ? 0.5 : i / (bladeCount - 1);
      final x = size.width * (0.08 + t * 0.84);
      final bladeHeight = size.height * (0.18 + (i.isEven ? 0.08 : 0.0));
      final lean = size.width * 0.03 * (i.isEven ? 1 : -1);

      final path = Path()..moveTo(x, baseY);
      path.quadraticBezierTo(
        x + lean, baseY - bladeHeight * 0.6,
        x + lean * 1.4, baseY - bladeHeight,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteppeTexturePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bladeCount != bladeCount;
}
