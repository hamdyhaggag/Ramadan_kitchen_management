import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/widgets/password_field.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_texts.dart';
import '../../../../../core/widgets/general_button.dart';

class ResetPasswordViewBody extends StatefulWidget {
  const ResetPasswordViewBody({super.key});

  @override
  State<ResetPasswordViewBody> createState() => _ResetPasswordViewBodyState();
}

class _ResetPasswordViewBodyState extends State<ResetPasswordViewBody> {
  final formKey = GlobalKey<FormState>();
  AutovalidateMode authvalidateMode = AutovalidateMode.disabled;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  @override
  void initState() {
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        autovalidateMode: authvalidateMode,
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * .05,
            ),
            PasswordField(
              controller: passwordController,
              hintText: AppTexts.password,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: confirmPasswordController,
              hintText: AppTexts.confirmPassword,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GeneralButton(
                text: AppTexts.createNewPassword,
                height: 60,
                backgroundColor: AppColors.primaryColor,
                textColor: AppColors.whiteColor,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                  } else {
                    authvalidateMode = AutovalidateMode.always;
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
