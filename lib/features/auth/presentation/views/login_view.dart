import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import '../manager/login_cubit/login_cubit.dart';
import 'widgets/login_view_body_bloc_consumer.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(
        getIt.get<AuthRepo>(),
      ),
      child: const Scaffold(
        body: LoginViewBodyBlocConsumer(),
      ),
    );
  }
}
