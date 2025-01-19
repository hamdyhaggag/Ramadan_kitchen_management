import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

abstract class AppStyles {
  static const TextStyle cairoBold24 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'Cairo',
    color: AppColors.primaryColor,
  );
  static const TextStyle cairoRegular16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Cairo',
    color: AppColors.primaryColor,
  );
  static const TextStyle cairoRegular14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'Cairo',
    color: AppColors.blackColor,
  );
  static const TextStyle cairoBold32 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: 'Cairo',
    color: AppColors.primaryColor,
  );
  static const TextStyle cairoBold20 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'Cairo',
    color: AppColors.blackColor,
  );
}
