import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repos/auth_repo.dart';
import 'register_cubit_state.dart';

class RegisterCubit extends Cubit<RegisterCubitState> {
  RegisterCubit(this.authRepo) : super(RegisterCubitInitial());
  final AuthRepo authRepo;

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    emit(RegisterCubitLoading());
    final result = await authRepo.createUserWithEmailAndPassword(
      email: email,
      password: password,
      userName: name,
      phoneNumber: phoneNumber,
    );
    result.fold(
      (failure) => emit(RegisterCubitError(failure.errMessage)),
      (user) => emit(RegisterCubitSuccess(userModel: user)),
    );
  }
}
