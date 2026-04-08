import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/members/application/bloc/members_state.dart';
import 'package:feature_toggle_app/features/members/application/usecase/load_members_usecase.dart';
import 'package:feature_toggle_app/features/members/application/usecase/remove_member_usecase.dart';
import 'package:feature_toggle_app/features/members/application/usecase/upsert_member_usecase.dart';
class MembersCubit extends Cubit<MembersState> {
  final LoadMembersUseCase _loadMembers;
  final UpsertMemberUseCase _upsertMember;
  final RemoveMemberUseCase _removeMember;

  static const _pageSize = 10;

  MembersCubit({
    required LoadMembersUseCase loadMembers,
    required UpsertMemberUseCase upsertMember,
    required RemoveMemberUseCase removeMember,
  })  : _loadMembers = loadMembers,
        _upsertMember = upsertMember,
        _removeMember = removeMember,
        super(const MembersInitial());

  Future<void> load({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
  }) async {
    emit(const MembersLoading());
    final result = await _loadMembers(
      accessToken: accessToken,
      projectId: projectId,
      page: page,
      size: _pageSize,
    );
    result.fold(
      (f) => emit(MembersError(f)),
      (paged) => emit(MembersLoaded(
        members: paged.items,
        totalElements: paged.totalElements,
        page: paged.page,
        totalPages: paged.totalPages,
      )),
    );
  }

  Future<void> add({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
    required String role,
  }) async {
    final result = await _upsertMember(
      accessToken: accessToken,
      projectId: projectId,
      userId: userId,
      role: role,
    );
    result.fold(
      (f) => emit(MembersError(f)),
      (created) {
        final current = state;
        if (current is MembersLoaded) {
          final list = [created, ...current.members];
          if (list.length > _pageSize) list.removeLast();
          emit(MembersLoaded(
            members: list,
            totalElements: current.totalElements + 1,
            page: current.page,
            totalPages: ((current.totalElements + 1) / _pageSize).ceil(),
          ));
        }
      },
    );
  }

  Future<void> changeRole({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
    required String role,
  }) async {
    final result = await _upsertMember(
      accessToken: accessToken,
      projectId: projectId,
      userId: userId,
      role: role,
    );
    result.fold(
      (f) => emit(MembersError(f)),
      (updated) {
        final current = state;
        if (current is MembersLoaded) {
          final list = current.members
              .map((m) => m.id == updated.id ? updated : m)
              .toList();
          emit(MembersLoaded(
            members: list,
            totalElements: current.totalElements,
            page: current.page,
            totalPages: current.totalPages,
          ));
        }
      },
    );
  }

  Future<void> remove({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
  }) async {
    final result = await _removeMember(
      accessToken: accessToken,
      projectId: projectId,
      userId: userId,
    );
    result.fold(
      (f) => emit(MembersError(f)),
      (_) {
        final current = state;
        if (current is MembersLoaded) {
          final list = current.members
              .where((m) => m.userId != userId)
              .toList();
          emit(MembersLoaded(
            members: list,
            totalElements: current.totalElements - 1,
            page: current.page,
            totalPages: (current.totalElements - 1) > 0
                ? ((current.totalElements - 1) / _pageSize).ceil()
                : 0,
          ));
        }
      },
    );
  }
}
