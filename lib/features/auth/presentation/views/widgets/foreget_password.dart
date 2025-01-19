import 'package:flutter/material.dart';

import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_styles.dart';
import '../../../../../core/utils/app_texts.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () 
          {
            Navigator.pushNamed(context, AppRoutes.forgetPassword);
          },
          child: Text(
            textAlign: TextAlign.start,
            AppTexts.forgetPassword,
            style:
                AppStyles.cairoRegular16.copyWith(color: AppColors.greyColor),
          ),
        ),
      ),
    );
  }
}
