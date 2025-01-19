import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ramadan_kitchen_management/views/auth/presentation/views/widgets/login_view_body.dart';

import '../../../../core/utils/app_colors.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: false,
          progressIndicator: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
          child: LoginViewBody(),
        ),
      ),
    );
  }
}
