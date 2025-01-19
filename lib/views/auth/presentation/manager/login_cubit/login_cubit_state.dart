import '../../../data/models/user_model.dart';

abstract class LoginCubitState {}

class LoginCubitInitial extends LoginCubitState {}

class LoginCubitError extends LoginCubitState {
  String errorMessage;
  LoginCubitError(this.errorMessage);
}

class LoginCubitSuccess extends LoginCubitState {
  UserModel userModel;
  LoginCubitSuccess({required this.userModel});
}

class LoginCubitLoading extends LoginCubitState {}
