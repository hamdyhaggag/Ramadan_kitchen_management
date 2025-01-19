import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_styles.dart';
import '../../../../core/utils/app_texts.dart';
import 'widgets/verify_view_body.dart';

class VerifyView extends StatelessWidget {
  const VerifyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.whiteColor,
        surfaceTintColor: AppColors.whiteColor,
        title: const Text(
          AppTexts.verifyYourRamz,
          style: AppStyles.cairoBold20,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const VerifyViewBody(),
    );
  }
}
