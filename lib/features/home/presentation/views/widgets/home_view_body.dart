import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/functions/get_current_user.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_styles.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Text(
            getCurrentUser().name,
            style: AppStyles.DINBold24.copyWith(color: AppColors.blackColor),
          ),
          Text(
            getCurrentUser().email,
            style: AppStyles.DINBold24.copyWith(color: AppColors.blackColor),
          ),
          Text(
            getCurrentUser().phoneNumber,
            style: AppStyles.DINBold24.copyWith(color: AppColors.blackColor),
          ),
        ],
      ),
    );
  }
}
