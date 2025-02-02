import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/features/auth/presentation/manager/reset_password_cubit/reset_password_state.dart';
import '../../../data/repos/auth_repo.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordCubitState> {
  ResetPasswordCubit(this.authRepo) : super(ResetPasswordCubitInitial());
  final AuthRepo authRepo;
  Future<void> resetPassword({required String email}) async {
    emit(ResetPasswordCubitLoading());
    final result = await authRepo.resetPassword(email: email);
    result.fold(
      (failure) =>
          emit(ResetPasswordCubitError(errMessage: failure.errMessage)),
      (right) => emit(
        ResetPasswordCubitSuccess(),
      ),
    );
  }
}
