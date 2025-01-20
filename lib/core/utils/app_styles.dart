import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

abstract class AppStyles {
  static const TextStyle dinBold24 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'DIN',
    color: AppColors.primaryColor,
  );
  static const TextStyle dinRegular16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'DIN',
    color: AppColors.primaryColor,
  );
  static const TextStyle dinRegular14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'DIN',
    color: AppColors.blackColor,
  );
  static const TextStyle dinBold32 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: 'DIN',
    color: AppColors.primaryColor,
  );
  static const TextStyle dinBold20 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'DIN',
    color: AppColors.blackColor,
  );
}
