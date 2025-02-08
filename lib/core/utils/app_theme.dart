import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

ThemeData lightTheme = ThemeData(
  // snackBarTheme: const SnackBarThemeData(
  //   backgroundColor: AppColors.blackColor,
  // ),
  brightness: Brightness.light,
  fontFamily: 'DIN',
  primaryColor: AppColors.primaryColor,
  scaffoldBackgroundColor: AppColors.whiteColor,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryColor,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.whiteColor,
    surfaceTintColor: AppColors.whiteColor,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.greyColor.withAlpha(128)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.greyColor.withAlpha(128)),
    ),
  ),
  // textButtonTheme: TextButtonThemeData(
  //   style: TextButton.styleFrom(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(
  //         12,
  //       ),
  //     ),
  //     backgroundColor: AppColors.primaryColor,
  //   ),
  // ),
  // textTheme: TextTheme(
  //   displayLarge: AppStyles.dinBold32.copyWith(color: AppColors.blackColor),
  //   headlineLarge: AppStyles.dinBold24.copyWith(color: AppColors.blackColor),
  //   bodyLarge: AppStyles.dinBold20.copyWith(color: AppColors.blackColor),
  //   bodyMedium: AppStyles.dinRegular16.copyWith(color: AppColors.blackColor),
  //   bodySmall: AppStyles.dinRegular14.copyWith(color: AppColors.blackColor),
  // )
);
