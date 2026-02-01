import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep; // 0-based
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            border: Border.all(
              color: isActive ? Colors.white : Color(0xFFC0C0C0),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
