import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';
import 'package:ramadan_kitchen_management/core/utils/app_styles.dart';
import 'package:ramadan_kitchen_management/core/utils/app_texts.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/manager/register_cubit/register_cubit.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_colors.dart';
import 'widgets/register_view_body_bloc_consumer.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(
        getIt.get<AuthRepo>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.whiteColor,
          surfaceTintColor: AppColors.whiteColor,
          title: const Text(
            AppTexts.newAccount,
            style: AppStyles.cairoBold20,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ),
        body: const RegisterViewBodyBlocConsumer(),
      ),
    );
  }
}
