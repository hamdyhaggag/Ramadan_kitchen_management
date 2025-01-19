import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_texts.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';

import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_styles.dart';
import 'custom_otp_field.dart';

class VerifyViewBody extends StatelessWidget {
  const VerifyViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .05),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppTexts.reEnterRamzThatWeSent,
                style: AppStyles.cairoRegular16.copyWith(
                  color: AppColors.blackColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Directionality(
            textDirection: TextDirection.ltr,
            child: CustomOtpField(),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GeneralButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.resetPassword);
              },
              text: AppTexts.verifyYourRamz,
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.whiteColor,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GeneralButton(
              onPressed: () {},
              text: AppTexts.resendRamz,
              textColor: AppColors.primaryColor,
              backgroundColor: AppColors.whiteColor,
            ),
          ),
          const SizedBox(height: 16)
        ],
      ),
    );
  }
}
