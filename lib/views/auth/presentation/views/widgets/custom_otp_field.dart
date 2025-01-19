import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../../core/utils/app_colors.dart';

class CustomOtpField extends StatelessWidget {
  const CustomOtpField({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: PinCodeTextField(
        validator: (data) {
          if (data!.isEmpty) {
            return 'field is requierd';
          }
          return null;
        },
        animationCurve: Curves.linear,
        animationType: AnimationType.scale,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        appContext: context,
        autoFocus: false,
        cursorColor: AppColors.primaryColor,
        cursorWidth: 2,
        cursorHeight: 25,
        showCursor: true,
        keyboardType: TextInputType.number,
        length: 4,
        obscureText: false,
        pinTheme: PinTheme(
          disabledBorderWidth: .5,
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(12),
          fieldHeight: 56,
          fieldWidth: 66,
          borderWidth: .5,
          activeColor: AppColors.primaryColor,
          inactiveColor: Colors.black.withAlpha(100),
          inactiveFillColor: Colors.white,
          activeFillColor: Colors.grey.shade100,
          selectedColor: AppColors.primaryColor,
          selectedFillColor: Colors.white,
        ),
        animationDuration: const Duration(milliseconds: 300),
        backgroundColor: Colors.white,
        enableActiveFill: true,
        onCompleted: (submitedCode) {
          // otpCode = submitedCode;
          log("Completed");
        },
        // onChanged: (value) {
        //   log(value);
        // },
      ),
    );
  }
}
