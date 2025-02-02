import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/cache/prefs.dart';
import '../../../../core/constants/backend_endpoints.dart';
import '../../../../core/constants/constatnts.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/data_base_service.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../models/user_model.dart';
import 'auth_repo.dart';

class AuthRepoImpl extends AuthRepo {
  final FirebaseAuthService firebaseAuthService;
  final DatabaseService databaseService;

  AuthRepoImpl(
      {required this.firebaseAuthService, required this.databaseService});

  @override
  UserModel? get currentUser {
    final userData = Prefs.getString(kUserData);
    return userData != null ? UserModel.fromJson(jsonDecode(userData)) : null;
  }

  @override
  Future<bool> isAdmin(String uid) async {
    final userData = await databaseService.getData(
      path: BackendEndpoints.kUsers,
      docuementId: uid,
    );
    return (userData?['role'] as String?) == 'admin';
  }

  @override
  Future<Either<Failure, UserModel>> createUserWithEmailAndPassword({
    required String userName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    User? user;
    try {
      user = await firebaseAuthService.createUserWithEmailAndPassword(
          email: email, password: password);
      final userModel = UserModel(
          uid: user.uid,
          name: userName,
          email: email,
          phoneNumber: phoneNumber);
      await addUserData(user: userModel);
      await saveUserData(user: userModel);
      return Right(userModel);
    } catch (e) {
      await deleteUser(user);
      return Left(FirebaseAuthFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signinWithEmailAndPassword(
      String email, String password) async {
    try {
      final user = await firebaseAuthService.signInWithEmailAndPassword(
          email: email, password: password);
      final currentUser = await getUserData(uid: user.uid);
      await saveUserData(user: currentUser);
      return Right(currentUser);
    } on CustomException catch (e) {
      return Left(FirebaseAuthFailure(errMessage: e.message));
    }
  }

  @override
  Future addUserData({required UserModel user}) async {
    await databaseService.addData(
        path: BackendEndpoints.kUsers,
        data: user.toMap(),
        documentId: user.uid);
  }

  @override
  Future saveUserData({required UserModel user}) async {
    await Prefs.setString(kUserData, jsonEncode(user.toMap()));
  }

  Future<UserModel> getUserData({required String uid}) async {
    final userData = await databaseService.getData(
        path: BackendEndpoints.kUsers, docuementId: uid);
    return UserModel.fromJson(userData);
  }

  @override
  Future<void> deleteUser(User? user) async {
    if (user != null) await firebaseAuthService.deleteUser();
  }

  @override
  Future<void> signOut() async {
    await firebaseAuthService.signOut();
    await Prefs.remove(kUserData);
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await firebaseAuthService.resetPassword(email: email);
      return const Right(null);
    } on CustomException catch (e) {
      return Left(FirebaseAuthFailure(errMessage: e.message));
    }
  }
}
