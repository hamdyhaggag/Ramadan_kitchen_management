import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/views/widgets/forget_password_view_body_bloc_consumer.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/utils/app_texts.dart';
import '../../data/repos/auth_repo.dart';
import '../manager/reset_password_cubit/reset_password_cubit.dart';

class ForgetPasswordView extends StatelessWidget {
  const ForgetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResetPasswordCubit(
        getIt.get<AuthRepo>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            AppTexts.forgetPassword,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ),
        body: const ForgetPasswordViewBodyBlocConsumer(),
      ),
    );
  }
}
