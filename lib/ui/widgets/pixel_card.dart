
import 'package:flutter/material.dart';

class PixelCard extends StatelessWidget {
  final Widget child;

  const PixelCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18221C),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}