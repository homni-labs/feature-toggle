import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/users/application/bloc/users_state.dart';
import 'package:togli_app/features/users/application/usecase/load_users_usecase.dart';
import 'package:togli_app/features/users/application/usecase/update_user_usecase.dart';

class UsersCubit extends Cubit<UsersState> {
  final LoadUsersUseCase _loadUsers;
  final UpdateUserUseCase _updateUser;

  static const _pageSize = 10;

  UsersCubit({
    required LoadUsersUseCase loadUsers,
    required UpdateUserUseCase updateUser,
  })  : _loadUsers = loadUsers,
        _updateUser = updateUser,
        super(const UsersInitial());

  Future<void> load({
    required String accessToken,
    int page = 0,
  }) async {
    emit(const UsersLoading());
    final result = await _loadUsers(
      accessToken: accessToken,
      page: page,
      size: _pageSize,
    );
    result.fold(
      (f) => emit(UsersError(f)),
      (paged) => emit(UsersLoaded(
        users: paged.items,
        totalElements: paged.totalElements,
        page: paged.page,
        totalPages: paged.totalPages,
      )),
    );
  }

  Future<void> toggleRole({
    required String accessToken,
    required UserId userId,
    required String newRole,
  }) async {
    final result = await _updateUser(
      accessToken: accessToken,
      userId: userId,
      platformRole: newRole,
    );
    result.fold(
      (f) => emit(UsersError(f)),
      (updated) {
        final current = state;
        if (current is UsersLoaded) {
          final list = current.users
              .map((u) => u.id == updated.id ? updated : u)
              .toList();
          emit(UsersLoaded(
            users: list,
            totalElements: current.totalElements,
            page: current.page,
            totalPages: current.totalPages,
          ));
        }
      },
    );
  }

  Future<void> toggleActive({
    required String accessToken,
    required UserId userId,
    required bool active,
  }) async {
    final result = await _updateUser(
      accessToken: accessToken,
      userId: userId,
      active: active,
    );
    result.fold(
      (f) => emit(UsersError(f)),
      (updated) {
        final current = state;
        if (current is UsersLoaded) {
          final list = current.users
              .map((u) => u.id == updated.id ? updated : u)
              .toList();
          emit(UsersLoaded(
            users: list,
            totalElements: current.totalElements,
            page: current.page,
            totalPages: current.totalPages,
          ));
        }
      },
    );
  }
}
