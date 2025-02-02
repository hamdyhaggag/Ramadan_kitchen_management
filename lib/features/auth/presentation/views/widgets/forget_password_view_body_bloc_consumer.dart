import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../../../../core/functions/show_snack_bar.dart';
import '../../../../../core/utils/app_texts.dart';
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
          showSnackBar(context, AppTexts.lookToYourEmail);
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          inAsyncCall: state is ResetPasswordCubitLoading,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ForgetPasswordViewBody(),
          ),
        );
      },
    );
  }
}
