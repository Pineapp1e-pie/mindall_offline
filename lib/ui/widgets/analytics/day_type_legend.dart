import 'package:flutter/material.dart';

class DayTypeLegend extends StatelessWidget {
  const DayTypeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18221C),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      width: double.infinity,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ColorLabel(color: Color(0xFF7EC8E3), label: 'Стабильный'),
          SizedBox(height: 4),
          ColorLabel(color: Color(0xFFB8A9E3), label: 'Сбалансированный'),
          SizedBox(height: 4),
          ColorLabel(color: Color(0xFFF4A261), label: 'Контрастный'),
        ],
      ),
    );
  }
}

class ColorLabel extends StatelessWidget {
  final Color color;
  final String label;

  const ColorLabel({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
