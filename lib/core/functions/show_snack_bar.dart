import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(
        text,
        style: AppStyles.cairoRegular14.copyWith(
          color: AppColors.whiteColor,
        ),
      ),
    ),
  );
}
