import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/helpers/app_regex.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import '../../../../../core/functions/show_snack_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_texts.dart';
import '../../../../../core/widgets/custom_text_form_field.dart';
import '../../../../../core/widgets/password_field.dart';
import '../../manager/register_cubit/register_cubit.dart';
import 'terms_and_conditions.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool isTermsAccepted = false;
  AutovalidateMode autoValidateMode = AutovalidateMode.disabled;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController phoneController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    phoneController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: autoValidateMode,
      key: formKey,
      child: Column(
        children: [
          CustomTextFormField(
            controller: nameController,
            hitnText: AppTexts.fullName,
            textInputType: TextInputType.name,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            validator: (data) {
              if (data == null || data.isEmpty) {
                return AppTexts.fieldIsRequired;
              } else if (!AppRegex.isEmailValid(data)) {
                return AppTexts.invalidEmail;
              }
              return null;
            },
            controller: emailController,
            hitnText: AppTexts.email,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            validator: (data) {
              if (data == null || data.isEmpty) {
                return AppTexts.enterPhoneNumber;
              }
              final regex = RegExp(r'^(010|011|012|015)\d{8}$');
              if (!regex.hasMatch(data)) {
                return AppTexts.invalidPhoneNumber;
              }
              return null;
            },
            controller: phoneController,
            hitnText: AppTexts.phoneNumber,
            textInputType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: passwordController,
            hintText: AppTexts.password,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: confirmPasswordController,
            hintText: AppTexts.confirmPassword,
          ),
          const SizedBox(height: 16),
          TermsAncConditions(
            onChanged: (bool value) {
              setState(() {
                isTermsAccepted = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GeneralButton(
              onPressed: () async {
                await handlingRegister(context);
              },
              text: AppTexts.createNewAccount,
              backgroundColor: isTermsAccepted
                  ? AppColors.primaryColor
                  : AppColors.greyColor,
              textColor: AppColors.whiteColor,
            ),
          )
        ],
      ),
    );
  }

  Future<void> handlingRegister(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (isTermsAccepted) {
        if (passwordController.text == confirmPasswordController.text) {
          await context.read<RegisterCubit>().register(
                name: nameController.text,
                email: emailController.text,
                password: passwordController.text,
                phoneNumber: phoneController.text,
              );
        } else {
          showSnackBar(context, AppTexts.passwordNotMatch);
          autoValidateMode = AutovalidateMode.always;
          setState(() {});
        }
      } else {
        showSnackBar(
          context,
          AppTexts.pleaseAcceptTermsAndConditions,
        );
      }
    } else {
      autoValidateMode = AutovalidateMode.always;
      setState(() {});
    }
  }
}
