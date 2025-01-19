import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_styles.dart';
import '../../../../core/utils/app_texts.dart';
import 'widgets/forget_password_view_body.dart';

class ForgetPasswordView extends StatelessWidget {
  const ForgetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        surfaceTintColor: AppColors.whiteColor,
        centerTitle: true,
        title: Text(
          AppTexts.forgetPassword,
          style: AppStyles.cairoBold20,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.login),
        ),
      ),
      body: const ForgetPasswordViewBody(),
    );
  }
}
