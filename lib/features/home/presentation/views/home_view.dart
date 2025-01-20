import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/cache/prefs.dart';
import 'package:ramadan_kitchen_management/core/routes/app_routes.dart';
import 'package:ramadan_kitchen_management/core/services/firebase_auth_service.dart';
import 'package:ramadan_kitchen_management/features/home/presentation/views/widgets/home_view_body.dart';
import '../../../../core/constants/constatnts.dart';
import '../../../../core/utils/app_styles.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "الرئيسية",
          style: AppStyles.DINBold20,
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            //
            await FirebaseAuthService().signOut();
            log(FirebaseAuthService().isLoggedIn().toString());
            Prefs.removeData(key: kUserData);
            log(Prefs.getString(kUserData).toString());
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ),
      body: const HomeViewBody(),
    );
  }
}
