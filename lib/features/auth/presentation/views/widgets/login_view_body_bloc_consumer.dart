import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/manager/login_cubit/login_cubit.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../../../../core/functions/show_snack_bar.dart';
import '../../../../../core/utils/app_colors.dart';
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
          child: Stack(
            children: [
              ModalProgressHUD(
                inAsyncCall: state is LoginCubitLoading,
                progressIndicator: const SizedBox(), // Placeholder
                child: const LoginViewBody(),
              ),
              if (state is LoginCubitLoading)
                _buildCustomLoadingOverlay(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomLoadingOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6), // Semi-transparent overlay
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              height: 80,
              width: 80,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'جار تسجيل الدخول...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black38,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
