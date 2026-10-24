import 'package:flutter/material.dart';
import '../../core/repair/repair_session.dart';

class ToolArtwork extends StatelessWidget {
  final RepairTool tool;
  final double size;
  const ToolArtwork(this.tool, {super.key, this.size = 42});
  @override
  Widget build(BuildContext context) {
    if (tool == RepairTool.hand || tool == RepairTool.meter) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ToolPainter(tool)),
      );
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F7),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Image.asset(
        'assets/repair/tools/${tool.name}.jpg',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _ToolPainter extends CustomPainter {
  final RepairTool tool;
  _ToolPainter(this.tool);
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 60, s.height / 60);
    if (tool == RepairTool.hand) {
      final hand =
          Path()
            ..moveTo(22, 55)
            ..lineTo(10, 39)
            ..quadraticBezierTo(5, 30, 10, 28)
            ..quadraticBezierTo(14, 28, 21, 36)
            ..lineTo(21, 10)
            ..quadraticBezierTo(21, 3, 26, 3)
            ..quadraticBezierTo(31, 3, 31, 10)
            ..lineTo(31, 27)
            ..quadraticBezierTo(33, 17, 37, 21)
            ..lineTo(39, 29)
            ..quadraticBezierTo(42, 22, 45, 26)
            ..lineTo(47, 33)
            ..quadraticBezierTo(51, 28, 54, 34)
            ..lineTo(55, 44)
            ..quadraticBezierTo(52, 55, 47, 58)
            ..lineTo(27, 58)
            ..close();
      c.drawPath(
        hand,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFF1F6FA), Color(0xFFB1C4D1)],
          ).createShader(const Rect.fromLTWH(5, 0, 50, 60)),
      );
      c.drawPath(
        hand,
        Paint()
          ..color = const Color(0xFF668396)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7,
      );
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 2, 37, 54),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFFEFBD35),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 8, 27, 16),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFBDD5C5),
      );
      final tp = TextPainter(
        text: const TextSpan(
          text: '4.20',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Roboto',
            color: Color(0xFF183D32),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, const Offset(17, 10));
      c.drawCircle(
        const Offset(28, 37),
        9,
        Paint()..color = const Color(0xFF26343A),
      );
      c.drawLine(
        const Offset(28, 37),
        const Offset(31, 30),
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 3,
      );
      c.drawPath(
        Path()
          ..moveTo(22, 52)
          ..cubicTo(12, 58, 1, 59, 3, 45)
          ..lineTo(6, 31),
        Paint()
          ..color = const Color(0xFFEF6256)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      c.drawPath(
        Path()
          ..moveTo(34, 52)
          ..cubicTo(48, 60, 56, 57, 54, 43)
          ..lineTo(51, 29),
        Paint()
          ..color = const Color(0xFF20272A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _ToolPainter old) => old.tool != tool;
}
