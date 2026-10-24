import 'dart:math' as math;
import 'package:flutter/material.dart';

const lumaPurple = Color(0xFF7938FF);
const lumaInk = Color(0xFF150A3C);
const lumaMuted = Color(0xFF827B9C);

class LumaCard extends StatelessWidget {
  final String design, holder;
  final bool business, demo, mini;
  const LumaCard({
    super.key,
    this.design = 'classic',
    this.holder = 'TECHLIFE',
    this.business = false,
    this.demo = false,
    this.mini = false,
  });
  @override
  Widget build(BuildContext context) {
    final light = design == 'pearl' || design == 'chrome' || design == 'gold';
    final ink = light ? lumaInk : Colors.white;
    return MediaQuery.withNoTextScaling(
      child: AspectRatio(
        aspectRatio: 1.82,
        child: LayoutBuilder(
          builder: (context, c) {
            final unit = c.maxWidth / 340;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20 * unit),
                boxShadow: [
                  BoxShadow(
                    color: lumaPurple.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * unit),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _CardArt(design)),
                    Padding(
                      padding: EdgeInsets.all(23 * unit),
                      child: DefaultTextStyle(
                        style: TextStyle(color: ink, fontFamily: 'Roboto'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 31 * unit,
                                  height: 35 * unit,
                                  child: CustomPaint(painter: _LumaMark(light)),
                                ),
                                SizedBox(width: 8 * unit),
                                Text(
                                  'Luma',
                                  style: TextStyle(
                                    fontSize: 24 * unit,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const Spacer(),
                                Transform.rotate(
                                  angle: math.pi / 2,
                                  child: Icon(
                                    Icons.wifi,
                                    color: ink,
                                    size: 25 * unit,
                                  ),
                                ),
                              ],
                            ),
                            if (business)
                              Text(
                                'B U S I N E S S',
                                style: TextStyle(fontSize: 7 * unit),
                              ),
                            const Spacer(),
                            Container(
                              width: 43 * unit,
                              height: 32 * unit,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6 * unit),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF9FAFC),
                                    Color(0xFFBEC0CA),
                                    Color(0xFFF9FAFC),
                                  ],
                                ),
                              ),
                              child: CustomPaint(painter: _ChipPainter()),
                            ),
                            const Spacer(),
                            FittedBox(
                              child: Text(
                                '••••  ••••  ••••  ${demo
                                    ? '••••'
                                    : business
                                    ? '6082'
                                    : '2048'}',
                                style: TextStyle(
                                  fontSize: 20 * unit,
                                  letterSpacing: 2 * unit,
                                ),
                              ),
                            ),
                            SizedBox(height: 14 * unit),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    demo ? 'YOUR NAME' : holder.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11 * unit,
                                      letterSpacing: 2 * unit,
                                    ),
                                  ),
                                ),
                                Text(
                                  demo ? '••/••' : '12/30',
                                  style: TextStyle(fontSize: 12 * unit),
                                ),
                                Text(
                                  '  |  debit',
                                  style: TextStyle(fontSize: 11 * unit),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardArt extends CustomPainter {
  final String design;
  _CardArt(this.design);
  @override
  void paint(Canvas canvas, Size s) {
    final colors = switch (design) {
      'pearl' => [
        const Color(0xFFFFFCF7),
        const Color(0xFFE5DBF3),
        const Color(0xFFFAEEE7),
      ],
      'midnight' => [
        const Color(0xFF090713),
        const Color(0xFF24135B),
        const Color(0xFF030309),
      ],
      'aurora' => [
        const Color(0xFF11103A),
        const Color(0xFF34208E),
        const Color(0xFF111242),
      ],
      'chrome' => [
        const Color(0xFFF4F6FA),
        const Color(0xFF8994B4),
        const Color(0xFFE5EAF5),
      ],
      'gold' => [
        const Color(0xFFAE7C28),
        const Color(0xFFFFE4A1),
        const Color(0xFFC3964D),
      ],
      _ => [
        const Color(0xFF9E7BFF),
        const Color(0xFF6538D6),
        const Color(0xFF401EAA),
      ],
    };
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ).createShader(Offset.zero & s),
    );
    for (var i = 0; i < 3; i++) {
      final path =
          Path()
            ..moveTo(s.width * (.52 + i * .16), -10)
            ..cubicTo(
              s.width * .60,
              s.height * .5,
              s.width * 1.15,
              s.height * .35,
              s.width * 1.1,
              s.height * 1.1,
            )
            ..lineTo(s.width * .35, s.height * 1.3)
            ..cubicTo(
              s.width * .3,
              s.height * .63,
              s.width * 1.05,
              s.height * .45,
              s.width * (.52 + i * .16),
              -10,
            )
            ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: .03),
              design == 'aurora'
                  ? const Color(0xFF7DE8ED).withValues(alpha: .55)
                  : Colors.white.withValues(alpha: .30),
              Colors.white.withValues(alpha: .02),
            ],
          ).createShader(Offset.zero & s),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6,
      );
    }
  }

  @override
  bool shouldRepaint(_CardArt old) => design != old.design;
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p =
        Paint()
          ..color = const Color(0xFF8E8A9E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * .32, 0, s.width * .36, s.height),
        const Radius.circular(8),
      ),
      p,
    );
    for (final y in [.33, .67]) {
      c.drawLine(
        Offset(0, s.height * y),
        Offset(s.width * .32, s.height * y),
        p,
      );
      c.drawLine(
        Offset(s.width * .68, s.height * y),
        Offset(s.width, s.height * y),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_ChipPainter old) => false;
}

class _LumaMark extends CustomPainter {
  final bool dark;
  _LumaMark(this.dark);
  @override
  void paint(Canvas c, Size s) {
    final p =
        Path()
          ..moveTo(s.width * .64, 0)
          ..cubicTo(
            -s.width * .13,
            s.height * .02,
            -s.width * .19,
            s.height * .93,
            s.width * .56,
            s.height,
          )
          ..cubicTo(
            s.width * .79,
            s.height * 1.01,
            s.width * .98,
            s.height * .82,
            s.width,
            s.height * .73,
          )
          ..cubicTo(
            s.width * .45,
            s.height * .84,
            s.width * .20,
            s.height * .33,
            s.width * .64,
            0,
          )
          ..close();
    c.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              dark
                  ? [const Color(0xFFB995FF), lumaPurple]
                  : [Colors.white, const Color(0xFFBA9DFF), Colors.white],
        ).createShader(Offset.zero & s),
    );
    final fold =
        Path()
          ..moveTo(s.width * .64, 0)
          ..cubicTo(
            s.width * .1,
            s.height * .25,
            s.width * .36,
            s.height * .52,
            s.width * .47,
            s.height * .57,
          )
          ..cubicTo(
            s.width * .7,
            s.height * .79,
            s.width * .83,
            s.height * .7,
            s.width,
            s.height * .73,
          )
          ..cubicTo(
            s.width * .42,
            s.height * .70,
            s.width * .32,
            s.height * .18,
            s.width * .64,
            0,
          )
          ..close();
    c.drawPath(
      fold,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFDAC2FF),
            dark ? lumaPurple : const Color(0xFF9B77E7),
          ],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(_LumaMark old) => old.dark != dark;
}
