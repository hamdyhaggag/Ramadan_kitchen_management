import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repos/auth_repo.dart';
import 'login_cubit_state.dart';

class LoginCubit extends Cubit<LoginCubitState> {
  LoginCubit(this.authRepo) : super(LoginCubitInitial());

  final AuthRepo authRepo;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(LoginCubitLoading());
    final result = await authRepo.signinWithEmailAndPassword(email, password);
    result.fold(
      (failure) => emit(LoginCubitError(failure.errMessage)),
      (user) => emit(LoginCubitSuccess(userModel: user)),
    );
  }
}
