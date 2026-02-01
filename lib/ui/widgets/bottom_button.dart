import 'package:flutter/material.dart';

class BottomButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const BottomButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24,48),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: const Color(0xFF555555),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'DotGothic',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
