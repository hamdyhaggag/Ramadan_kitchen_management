import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class MealDescription extends StatelessWidget {
  final String description;

  const MealDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.whiteColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.blackColor,
                height: 1.6,
              ),
        ),
      ),
    );
  }
}
