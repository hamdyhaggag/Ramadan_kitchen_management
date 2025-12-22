import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/widgets/custom_user_app_bar.dart';
import 'package:ramadan_kitchen_management/features/home/presentation/views/widgets/home_view_body.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomUserAppBar(),
      body: HomeViewBody(),
    );
  }
}
