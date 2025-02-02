import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failure.dart';
import '../models/user_model.dart';

abstract class AuthRepo {
  UserModel? get currentUser;
  Future<bool> isAdmin(String uid);

  Future<Either<Failure, UserModel>> createUserWithEmailAndPassword({
    required String userName,
    required String email,
    required String password,
    required String phoneNumber,
  });

  Future<Either<Failure, UserModel>> signinWithEmailAndPassword(
      String email, String password);

  Future addUserData({required UserModel user});
  Future saveUserData({required UserModel user});
  Future<void> deleteUser(User? user);
  Future<void> signOut();
  Future<Either<Failure, void>> resetPassword({required String email});
}
