import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentStep / totalSteps,
              backgroundColor: AppTheme.lightGrey,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Step $currentStep of $totalSteps',
          style: const TextStyle(
            color: AppTheme.textGrey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
