import '../../../data/models/user_model.dart';

abstract class RegisterCubitState {}

class RegisterCubitInitial extends RegisterCubitState {}

class RegisterCubitLoading extends RegisterCubitState {}

class RegisterCubitSuccess extends RegisterCubitState {
  final UserModel userModel;

  RegisterCubitSuccess({required this.userModel});
}

class RegisterCubitError extends RegisterCubitState {
  final String errMessage;
  RegisterCubitError(this.errMessage);
}
