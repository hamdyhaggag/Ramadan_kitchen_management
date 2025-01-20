import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:ramadan_kitchen_management/core/services/firebase_auth_service.dart';

import '../../../../../core/cache/prefs.dart';
import '../../../../../core/constants/constatnts.dart';
import '../../../../../core/utils/app_assets.dart';

class SplashViewBody extends StatefulWidget {
  const SplashViewBody({super.key});

  @override
  State<SplashViewBody> createState() => _SplashViewBodyState();
}

class _SplashViewBodyState extends State<SplashViewBody> {
  @override
  void initState() {
    super.initState();
    excuteNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(AppAssets.imagesSplash),
    );
  }

  Future<void> excuteNavigation() {
    return Future.delayed(
      const Duration(seconds: 2),
      () {
        if (Prefs.getBool(kIsOnBoardingViewed)) {
          if (!mounted) return;
          if (FirebaseAuthService().isLoggedIn()) {
            Navigator.pushReplacementNamed(context, AppRoutes.layout);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        } else {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.onBoarding);
        }
      },
    );
  }
}
// if (!mounted) return;
