import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

import '../../../../../core/functions/show_snack_bar.dart';
import '../../manager/reset_password_cubit/reset_password_cubit.dart';
import '../../manager/reset_password_cubit/reset_password_state.dart';
import 'forget_password_view_body.dart';

class ForgetPasswordViewBodyBlocConsumer extends StatelessWidget {
  const ForgetPasswordViewBodyBlocConsumer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordCubit, ResetPasswordCubitState>(
      listener: (context, state) {
        if (state is ResetPasswordCubitError) {
          showSnackBar(context, state.errMessage);
        }
        if (state is ResetPasswordCubitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              content: Row(
                children: [
                  const Icon(Icons.email, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'تم بنجاح! \nيرجى التحقق من بريدك الإلكتروني لإعادة تعيين كلمة المرور الخاصة بك.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          inAsyncCall: state is ResetPasswordCubitLoading,
          progressIndicator: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ForgetPasswordViewBody(),
          ),
        );
      },
    );
  }
}
