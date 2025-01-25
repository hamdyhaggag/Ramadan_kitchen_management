abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminUsersLoaded extends AdminState {
  final List<Map<String, dynamic>> users;
  AdminUsersLoaded(this.users);
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}
