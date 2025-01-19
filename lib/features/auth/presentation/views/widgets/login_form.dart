import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/manager/login_cubit/login_cubit.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_texts.dart';
import '../../../../../core/widgets/general_button.dart';
import '../../../../../core/widgets/custom_text_form_field.dart';
import '../../../../../core/widgets/password_field.dart';
import 'foreget_password.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AutovalidateMode autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: autoValidateMode,
      child: Column(
        children: [
          CustomTextFormField(
            controller: emailController,
            hitnText: AppTexts.email,
            textInputType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: passwordController,
            hintText: AppTexts.password,
          ),
          const SizedBox(height: 16),
          const ForgetPassword(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GeneralButton(
              text: AppTexts.login,
              height: 60,
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.whiteColor,
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  context.read<LoginCubit>().login(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                } else {
                  autoValidateMode = AutovalidateMode.always;
                  setState(() {});
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
