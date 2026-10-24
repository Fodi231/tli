import 'package:flutter/material.dart';
import '../core/theme.dart';

class IosBackdrop extends StatelessWidget {
  final Widget child;
  const IosBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final p = IosColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              p.dark
                  ? const [
                    Color(0xFF1B2539),
                    Color(0xFF111216),
                    Color(0xFF1B172B),
                  ]
                  : const [
                    Color(0xFFEAF2FF),
                    Color(0xFFF4F4F9),
                    Color(0xFFEFE8FB),
                  ],
        ),
      ),
      child: child,
    );
  }
}

const profileColors = [
  Color(0xFF3478F6),
  Color(0xFF8052E9),
  Color(0xFF008D95),
  Color(0xFFD35C88),
  Color(0xFFD4762B),
  Color(0xFF3E8464),
];

class ProfileAvatar extends StatelessWidget {
  final String name;
  final int index;
  final double size;
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.index,
    this.size = 58,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          profileColors[index.clamp(0, 5)].withValues(alpha: .65),
          profileColors[index.clamp(0, 5)],
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .5), width: 1.5),
    ),
    alignment: Alignment.center,
    child:
        name.trim().isEmpty
            ? Icon(Icons.person_rounded, size: size * .57, color: Colors.white)
            : Text(
              name.trim().characters.first.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * .4,
                fontWeight: FontWeight.w700,
              ),
            ),
  );
}

class IosSectionTitle extends StatelessWidget {
  final String text;
  final String? detail;
  const IosSectionTitle(this.text, {super.key, this.detail});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 13, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 21,
              letterSpacing: -.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (detail != null)
          Text(
            detail!,
            style: TextStyle(
              color: IosColors.of(context).secondary,
              fontSize: 13,
            ),
          ),
      ],
    ),
  );
}
