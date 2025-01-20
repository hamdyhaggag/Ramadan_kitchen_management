import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../../../../core/functions/show_snack_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../manager/login_cubit/login_cubit.dart';
import '../../manager/login_cubit/login_cubit_state.dart';
import 'login_view_body.dart';

class LoginViewBodyBlocConsumer extends StatelessWidget {
  const LoginViewBodyBlocConsumer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginCubitState>(
      listener: (context, state) {
        if (state is LoginCubitSuccess) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.layout,
            (route) => false,
          );
        }
        if (state is LoginCubitError) {
          showSnackBar(context, state.errorMessage);
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: ModalProgressHUD(
            inAsyncCall: state is LoginCubitLoading,
            progressIndicator: const CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
            child: const LoginViewBody(),
          ),
        );
      },
    );
  }
}
