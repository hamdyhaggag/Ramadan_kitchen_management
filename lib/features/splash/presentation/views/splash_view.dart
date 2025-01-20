import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import 'widgets/splash_view_body.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SplashViewBody(),
    );
  }
}
// this is splash view branch
