import 'package:flutter/material.dart';

class GradientBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const GradientBlob({
    super.key,
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.5,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.map((c) => c.withOpacity(0.15)).toList(),
          ),
        ),
      ),
    );
  }
}
