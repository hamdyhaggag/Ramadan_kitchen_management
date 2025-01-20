import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_texts.dart';

import '../../../../../core/utils/app_assets.dart';
import '../../../../../core/utils/app_styles.dart';
import 'do_not_have_an_account.dart';
import 'login_form.dart';

class LoginViewBody extends StatelessWidget {
  const LoginViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      reverse: true,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .1),
          Image.asset(
            AppAssets.imagesSplash,
            height: MediaQuery.of(context).size.height * .3,
          ),
          const SizedBox(height: 16),
          const Text(
            textAlign: TextAlign.start,
            AppTexts.login,
            style: AppStyles.cairoBold20,
          ),
          const SizedBox(height: 16),
          const LoginForm(),
          const DoNotHaveAnAccount(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
