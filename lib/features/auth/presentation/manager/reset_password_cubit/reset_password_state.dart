abstract class ResetPasswordCubitState {}

class ResetPasswordCubitInitial extends ResetPasswordCubitState {}

class ResetPasswordCubitSuccess extends ResetPasswordCubitState {}

class ResetPasswordCubitError extends ResetPasswordCubitState {
  final String errMessage;
  ResetPasswordCubitError({required this.errMessage});
}

class ResetPasswordCubitLoading extends ResetPasswordCubitState {}
