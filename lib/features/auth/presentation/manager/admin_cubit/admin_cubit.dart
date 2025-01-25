import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/backend_endpoints.dart';
import '../../../../../core/services/data_base_service.dart';
import '../../../data/repos/auth_repo.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AuthRepo authRepo;
  final DatabaseService databaseService;

  AdminCubit(this.authRepo, this.databaseService) : super(AdminInitial());

  Future<void> getAllUsers() async {
    emit(AdminLoading());
    try {
      final currentUid = authRepo.currentUser?.uid;
      if (currentUid == null || !await authRepo.isAdmin(currentUid)) {
        throw Exception('Unauthorized access');
      }

      final users = await databaseService.getAllData(BackendEndpoints.kUsers);
      emit(AdminUsersLoaded(users.cast<Map<String, dynamic>>()));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
