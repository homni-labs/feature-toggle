import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/auth/domain/model/user.dart';

sealed class UsersState {
  const UsersState();
}

class UsersInitial extends UsersState {
  const UsersInitial();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  final List<User> users;
  final int totalElements;
  final int page;
  final int totalPages;

  const UsersLoaded({
    required this.users,
    required this.totalElements,
    required this.page,
    required this.totalPages,
  });
}

class UsersError extends UsersState {
  final Failure failure;
  const UsersError(this.failure);
}
