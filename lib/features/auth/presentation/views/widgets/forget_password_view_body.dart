import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:ramadan_kitchen_management/core/utils/app_texts.dart';
import 'package:ramadan_kitchen_management/core/widgets/custom_text_form_field.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_styles.dart';

class ForgetPasswordViewBody extends StatelessWidget {
  const ForgetPasswordViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      reverse: true,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .05),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppTexts.doNotWorry,
                style: AppStyles.dinRegular16.copyWith(
                  color: AppColors.blackColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const CustomTextFormField(
            hitnText: AppTexts.enterYourPhoneNumber,
            textInputType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GeneralButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.verify);
              },
              text: AppTexts.forgetPassword,
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }
}
