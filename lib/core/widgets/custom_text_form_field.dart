import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_texts.dart';

import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.onSaved,
    this.hitnText,
    this.controller,
    this.textInputType = TextInputType.text,
    this.validator,
  });
  final String? hitnText;
  final Function(String?)? onSaved;
  final TextEditingController? controller;
  final TextInputType? textInputType;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        textAlign: TextAlign.right,
        style: AppStyles.DINRegular16.copyWith(color: Colors.black),
        cursorColor: AppColors.primaryColor,
        keyboardType: textInputType,
        controller: controller,
        validator: validator ??
            (data) {
              if (data!.isEmpty) {
                return AppTexts.fieldIsRequired;
              }
              return null;
            },
        onSaved: onSaved,
        decoration: InputDecoration(
          errorStyle: AppStyles.DINRegular14.copyWith(color: Colors.red),
          hintText: hitnText,
          floatingLabelStyle: AppStyles.DINRegular16,
          hintStyle:
              AppStyles.DINRegular16.copyWith(color: AppColors.greyColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.greyColor.withAlpha(128)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.greyColor.withAlpha(128)),
          ),
        ),
      ),
    );
  }
}
