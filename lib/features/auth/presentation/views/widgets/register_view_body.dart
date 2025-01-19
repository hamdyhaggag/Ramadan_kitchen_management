import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/views/widgets/register_form.dart';

import 'already_have_an_account.dart';

class RegisterViewBody extends StatelessWidget {
  const RegisterViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      reverse: true,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .05),
          const RegisterForm(),
          const SizedBox(height: 16),
          const AlreadyHaveAnAccount(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
